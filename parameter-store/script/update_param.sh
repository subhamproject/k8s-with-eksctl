## Update a parameter
aws ssm put-parameter ^
--name "/mypstore/string_type/username" ^
--value "chandrima" ^
--type String ^
--overwrite

## Observe parameter version has been changed to version 2
