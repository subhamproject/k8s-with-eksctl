## You can also create a label for all the versions
aws ssm label-parameter-version ^
--name "/mypstore/string_type/username" ^
--parameter-version "1" ^
--labels "InitialNameDebjeet"

aws ssm label-parameter-version ^
--name "/mypstore/string_type/username" ^
--parameter-version "2" ^
--labels "changed_name_chandrima"
