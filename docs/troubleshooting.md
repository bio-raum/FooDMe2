# Common issues and errors


## `Too few reads - stopping sample SAMPLE after PCR primer removal!`

This error suggests that no or too few reads survived the PCR primer removal. Several things could cause this:

- Too few reads to begin with (see [requirements](requirements.md))
- The primer sequences are incorrect
- The reads were already trimmed; we only allow reads to pass that have been successfully primer trimmed inside of FooDMe2 to ensure a high data quality

## 


