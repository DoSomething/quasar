import logging
import re

# DoSomething Helper Functions - Code Reused Across Lots of our ETL Scripts

# String Parser


def strip_str(base_value):
    """Convert value to string and strips special characters.

    None becomes empty string
    """
    base_string = str(base_value)
    if base_string == 'None':
        return ''
    else:
        strip_special_chars = re.sub(r'[()<>/"\,\'\\]', '', base_string)
        return str(strip_special_chars)

# Error Logging


class QuasarException(Exception):
    """Donated exception handling code by Rob Spectre.

    This logs any error message we need to pass in.
    """

    def __init__(self, message):
        """Log errors with formatted messaging."""
        logging.error("ERROR: {0}".format(message))
        pass
