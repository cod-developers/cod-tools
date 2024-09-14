Tests the way CIF files that contain several common or systematic chemical names
are handled. While this is sometimes purposely done to provide several
alternatives names, more often this indicates that some kind of error has
occurred (e.g. a single chemical name got split into several looped values).
Since it is quite difficult to automatically distinguish between the two cases,
such looped values should be better skipped.
