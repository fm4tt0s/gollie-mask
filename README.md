# gollie-mask
CSV (aka delimited file) to JSON... Jason Voorhees waved at your CSVs!

## what
Convert CSV or other delimitedd file into JSON, whatever fields.

## how to
It's very straightforward
<pre>./gollie-mask.sh 

  Usage:
      ./gollie-mask.sh -d[alternative delimiter ',' - default is ';'] -f[file]

      ** first line assumed as header **

  Example:
      ./gollie-mask.sh -f file_to_process.csv
      ./gollie-mask.sh -d, -f file_to_process.csv

  Supported CSV formats:
      field1;field2
      field1,field2
      "field1","field2"   * not recommended
 </pre>
 
## Examples
- Default semicolon separator ';'
<pre>
$ cat semicolon-delimited-file
a;b;c
1;2;3
4;5;6

$ ./gollie-mask.sh -f semicollon-delimited-file
[   { "a" : "1","b" : "2","c" : "3" },{ "a" : "4","b" : "5","c" : "6" }   ]
</pre>

- Using a file delimited by commas ',' as separator
<pre>
$ cat commas-delimited-file
a,b,c
1,2,3
4,5,6

$ ./gollie-mask.sh -f commas-delimited-file -d,
[   { "a" : "1","b" : "2","c" : "3" },{ "a" : "4","b" : "5","c" : "6" }   ]
</pre>

## Remarks

- First line of the file is taken as header and used as JSON fields
- There is a very basic check-up for file format. It takes first line and count its columns, if remaining lines differ from it, file is considered malformed.
- Output is a unformatted JSON, you can pipe it to _python -m json.tool_ to get a **RFC 8259 JSON**, like

<pre>
$ ./gollie-mask.sh -f semicollon-delimited-file | python -m json.tool
[
    {
        "a": "1",
        "b": "2",
        "c": "3"
    },
    {
        "a": "4",
        "b": "5",
        "c": "6"
    }
]
</pre>
