$i=0; while($true)
{
    % { $i++; write-host -NoNewline "$i $_" }
    (Invoke-RestMethod "http://$1:$2")-replace '\n', " "
}
