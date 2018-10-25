"""
These, and only these, functions should help you with treating your own code
in the context of one database transaction. Which makes our lived easier.
"""
import sys
from datetime import datetime

import pytz
import click
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.exc import DatabaseError

from bvp.data.config import db
from bvp.utils.error_utils import get_err_source_info
from bvp.data.models.task_runs import LatestTaskRun


def as_transaction(db_function):
    """Decorator for handling any function which contains SQLAlchemy commands as one database transaction (ACID).
    Calls db operation function and when it is done, commits the db session.
    Rolls back the session if anything goes wrong."""

    def wrap(db: SQLAlchemy, *args, **kwargs):
        try:
            db_function(db, *args, **kwargs)
            db.session.commit()
        except Exception as e:
            click.echo("[%s] Encountered Problem: %s" % (db_function.__name__, str(e)))
            db.session.rollback()
            raise
        finally:
            db.session.close()

    return wrap


def after_request_session_commit_or_rollback(exception):
    """Central place to handle transactions finally. So - usually your view code should
       not have to deal with committing or rolling back.

       Register this on your app via the teardown_request setup method.
       We roll back if there was any error and if committing doesn't work."""
    if exception is not None:
        db.session.rollback()
        db.session.close()
        return
    try:
        db.session.commit()
    except DatabaseError:
        db.session.rollback()
        raise
    finally:
        db.session.close()
    # session.remove() is called for us by flask-sqlalchemy


def task_with_status_report(task_function):
    """Decorator for tasks which should report their runtime and status in the db (as LatestTaskRun entries).
    Tasks decorated with this endpoint should also leave committing or rolling back the session to this
    decorator (for the reasons that it is nice to centralise that but also practically, this decorator
    still needs to add to the session)."""

    def wrap(*args, **kwargs):
        status: bool = True
        try:
            task_function(*args, **kwargs)
            click.echo("[BVP] Task %s ran fine." % task_function.__name__)
        except Exception as e:
            exc_info = sys.exc_info()
            last_traceback = exc_info[2]
            click.echo(
                '[BVP] Task %s encountered a problem: "%s". More details: %s'
                % (task_function.__name__, str(e), get_err_source_info(last_traceback))
            )
            status = False
        finally:
            try:
                # take care of finishing the transaction correctly
                if status is True:
                    db.session.commit()
                else:
                    db.session.rollback()

                # now save the status of the task
                task_name = task_function.__name__
                task_run = LatestTaskRun.query.filter(
                    LatestTaskRun.name == task_name
                ).one_or_none()
                if task_run is None:
                    task_run = LatestTaskRun(name=task_name)
                    db.session.add(task_run)
                task_run.datetime = datetime.utcnow().replace(tzinfo=pytz.utc)
                task_run.status = status
                db.session.commit()

            except Exception as e:
                click.echo(
                    "[BVP] Could not report the running of Task %s, encountered the following problem: %s"
                    % (task_function.__name__, str(e))
                )

    return wrap