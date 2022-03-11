$host=$1
$port=$2

$i=0; while($true)
{
    % { $i++; write-host -NoNewline "$i $_" }
    (Invoke-RestMethod "http://$host:$port")-replace '\n', " "
}
