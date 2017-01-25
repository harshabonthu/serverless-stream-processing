# serverless-stream-processing
Sample repository for Serverless Stream processing examples

## Truck Position Stream Processing

### Example filtering rules

- Remove event when it arrives within 4 minutes since the last received event for the same truckCode
- Remove event when it misses one of the following attributes
	- messageReport/source
	- messageReport/timestamp
	- truckReport/truckCode
	- positionReport/longitude
	- positionReport/latitude

### Example data enrichment steps

- Lookup truckDriverSSN and enrich event
- Lookup cargoType and enrich event
- Lookup road and enrich event (complex)
