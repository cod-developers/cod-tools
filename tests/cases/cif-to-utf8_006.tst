Tests the way symbols that contain a combining ring character are decoded.
Since a CIF special code for a combining ring character does not exist,
the combining character should be expressed using the HTML entity code.
The letter A is a special case and can be expressed using special CIF
codes ('\%A', '\%a'), however, the same syntax does not seem to extend
to other characters.
