# one second everyday backup script

A [thor](https://github.com/wycats/thor#thor) script I'm using to split and backup the seconds I record with the awesome [one second everyday app](http://1secondeveryday.com). The script uses ffmpeg to split a .mov file in single seconds and stores them into a directory structure. The script is also capable of merging the single chunks back into a single file.

## Requirements

* `ffmpeg` executable. Should be located in the script's directory.  
(download it at [ffmpeg.org](http://www.ffmpeg.org/download.html) and place it in the script directory).
* `streamio-ffmpeg` gem
* `thor` gem

## Usage
The output movies from the 1SE app have to be placed inside the script directory.

### Getting Help
`>thor onesecond:help`  
`>thor onesecond:help split`

### Split
`>thor onesecond:split FILE_NAME --start-date 2013-01-01`  
splits the FILE_NAME into 1 second chunks and places them into a directory structure (i.e. `/201301 January/2013-01-01.mov`). The `--start-date` parameter should be set to the first second's date. This is required to assign correct file names to the chunks.  
The split command ignores the last 5 seconds that normally show the 1SE logo. This can be overridden with the `--cut-from-end` parameter or by turning of the `--one-second-everyday-mode`.

### Autosplit
`>thor onesecond:auto_split`  
Auto-splitting searches for the .mov with the latest modified date and splits it into one second chunks. As date the Action uses the last created video chunk.  
Auto split requires that the split action ran at least once, and the directory structure is not modified.  
This action also uses the `--cut-from-end` and `--one-second-everyday-mode` parameters.

`>thor onesecond:auto_split FILE_NAME`  
Specify a file name for the `auto_split` function.

### Merge
`>thor onesecond:merge --start_date 2013-01-01 --end_date 2013-01-31`  
Merges the chunks from `2013-01-01` until `2013-01-31` into a new movie file. Specify the name of the output movie with the `--output-file`.

### Merge All
`>thor onesecond:merge_all`  
Merge all chunks available inside the directory structure. Merges the chunks of the last `--max-months` (default:12). Specify the name of the output movie with the `--output-file`.

### Process
`>thor onesecond:process`
Combines `autosplit` and `merge_all`. The new video is read in and all previous chunks are merged into a full movie.

## License
Copyright (c) 2013 Christian Peterek

MIT License

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
