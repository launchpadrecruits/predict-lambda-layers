import json
import logging
import logging.config as logging_config
import os
from datetime import date, datetime

from pygments import highlight
from pygments.formatters import TerminalFormatter
from pygments.lexers import JsonLexer

import structlog
from structlog import processors, stdlib
from structlog_sentry import SentryJsonProcessor

#                             --=== LOGGING ===--

RESET_COLORS = "\032[0m"

JSON_LOGS = os.environ.get("JSON_LOGS", True)
COLOR_LOGS = os.environ.get("COLOR_LOGS", False)
LOG_LEVEL = os.environ.get("LOG_LEVEL", "DEBUG")
INDENT = 4


def datetime_serializer(item):
    """JSON serializer for objects not serializable by default json code"""

    if isinstance(item, (datetime, date)):
        return item.isoformat()
    raise TypeError("Type {} not serializable".format(type(item)))


# Structured logging
def colorize_json_values(_, __, event_dict):
    """Highlight json syntax of complex payload data structures.
    Used only at line logs. Should be placed before a renderer.
    """
    new_event_dict = {}
    for k, v in event_dict.items():
        if isinstance(v, (dict, list, tuple)):
            new_event_dict[k] = highlight(
                json.dumps(v, default=datetime_serializer),
                JsonLexer(),
                TerminalFormatter(),
            )
            new_event_dict[k] = new_event_dict[k].rstrip("\n")
            new_event_dict[k] = RESET_COLORS + new_event_dict[k]
        else:
            new_event_dict[k] = v
    return new_event_dict


class ColoredJsonRenderer(structlog.processors.JSONRenderer):
    """JSON logs with syntax highlighting."""

    def __call__(self, logger, name, event_dict):
        return highlight(
            super(ColoredJsonRenderer, self).__call__(logger, name, event_dict),
            JsonLexer(),
            TerminalFormatter(),
        )


PROCESSORS = [
    stdlib.add_log_level,
    stdlib.add_logger_name,
    processors.TimeStamper(fmt="iso"),
    processors.format_exc_info,
    processors.StackInfoRenderer(),
]

if JSON_LOGS:
    if COLOR_LOGS:
        PROCESSORS += [
            SentryJsonProcessor(level=logging.ERROR, tag_keys="__all__"),
            ColoredJsonRenderer(sort_keys=True, indent=INDENT or None),
        ]
    else:
        PROCESSORS += [
            SentryJsonProcessor(level=logging.ERROR, tag_keys="__all__"),
            structlog.processors.JSONRenderer(sort_keys=True, indent=INDENT),
        ]
else:
    if COLOR_LOGS:
        PROCESSORS += [colorize_json_values]

logging_config.dictConfig(
    dict(
        version=1,
        formatters={"basic": {"format": "%(message)s"}},
        handlers={
            "stdout": {
                "class": "logging.StreamHandler",
                "formatter": "basic",
                "level": LOG_LEVEL,
                "stream": "ext://sys.stdout",
            }
        },
        root={"level": LOG_LEVEL, "handlers": ["stdout"]},
    )
)


def set_up(file):
    structlog.configure(
        processors=PROCESSORS,
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )
    return structlog.wrap_logger(logging.getLogger(file))


#                                --=== \|/ ===--
