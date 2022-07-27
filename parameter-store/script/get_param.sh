## Get parameter value by path
aws ssm get-parameters-by-path ^
--path "/mypstore/string_type/"

## Get a single parameter by name
aws ssm get-parameter ^
--name "/mypstore/string_type/username"

## Get multiple parameters by name
aws ssm get-parameters ^
--names "/mypstore/string_type/username" "/mypstore/secure_string/password"

## Get decrypted parameter values for secure string type
aws ssm get-parameters ^
--names "/mypstore/string_type/username" "/mypstore/secure_string/password" ^
--with-decryption
