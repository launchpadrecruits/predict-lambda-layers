import io
import json
import logging
import logging.config as logging_config
import os
from datetime import date, datetime
from inspect import getframeinfo, stack

import colorama
from pygments import highlight
from pygments.formatters import TerminalFormatter
from pygments.lexers import JsonLexer

import structlog
from structlog import processors, stdlib

#                             --=== LOGGING ===--

RESET_COLORS = "\032[0m"


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


def add_sourceline(_, __, event_dict):
    """Add source line to the current log statement."""
    rev_stack = list(reversed(stack()))
    local_frames = (i for i in rev_stack if i.filename == os.path.realpath(__file__))
    current_frame = next(local_frames)
    caller = getframeinfo(current_frame[0])
    event_dict["caller"] = "{}.{}+{}".format(
        os.path.relpath(caller.filename).rstrip(".py").replace("/", "."),
        caller.function,
        caller.lineno,
    )

    return event_dict


class SourceLineConsoleRenderer(structlog.dev.ConsoleRenderer):
    """Format a source line in the metadata of a line log."""

    def __call__(self, _, __, event_dict):
        sio = io.StringIO()
        caller = event_dict.pop("caller", None)
        msg_line = super(SourceLineConsoleRenderer, self).__call__(_, __, event_dict)
        if caller:
            sio.write(
                "{}{}{}: ".format(colorama.Fore.YELLOW, caller, self._styles.reset)
            )
            sio.write(msg_line)
            return sio.getvalue()
        return msg_line


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
    add_sourceline,
]

if bool(int(os.environ["JSON_LOGS"])):
    PROCESSORS += [ColoredJsonRenderer(sort_keys=True, indent=4)]
else:
    PROCESSORS += [
        colorize_json_values,
        SourceLineConsoleRenderer(
            level_styles=structlog.dev.ConsoleRenderer.get_default_level_styles()
        ),
    ]

logging_config.dictConfig(
    dict(
        version=1,
        formatters={"basic": {"format": "%(message)s"}},
        handlers={
            "stdout": {
                "class": "logging.StreamHandler",
                "formatter": "basic",
                "level": os.environ["LOG_LEVEL"],
                "stream": "ext://sys.stdout",
            }
        },
        root={"level": os.environ["LOG_LEVEL"], "handlers": ["stdout"]},
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
