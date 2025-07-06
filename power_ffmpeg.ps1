$encoding_prefix = '.tmp'  # Add to front of file name when in process of encoding
$sig = 'ffmpeg'  # Added to end of file name within square brackets to note the video was encoded by ffmpeg.
$sig_found_base_name = ''  # Used to hold file names that contains the $sig. used in event of continueing interupted encoding to ensure it does not re-encoded an encoded file.
$final_msg = '`n`nReport:'

foreach ($file in (ls | Sort-Object Name)){
  $extension = $file.Extension
  $base_name = $file.BaseName
  $name = $file.name
  $dir = $file.directoryName
  $tmp_name = "$($encoding_prefix) $($base_name) [$($sig)]$($extension)"  # Used when in process of encoding.
  $final_name = "$($base_name) [$($sig)]$($extension)"  # change tmp_name to final_name when done.

  # Check if its a folder.
  if ($file.PSIsContainer) {
    $final_msg += "`n Skipping folder: $($base_name)"
	continue
  }
  
  # Check if its a common video file.
  if ('.mkv', '.mp4', '.mov', '.avi' -notcontains $extension) {
    $final_msg += "`nNot a video file: $($base_name)"
	echo $extension
	continue
  }
  
  # Check if it contains .tmp meaning was prevously in process of encoding but got interupted.
  # delete file and Skip if true.
  if ($base_name -match "^\$($encoding_prefix)") {
    rm -LiteralPath $name
    echo "Tmp file deleted: $($base_name)"
    $final_msg += "`nTmp file deleted: $($base_name)"
    continue
  }

  # In case of prevously intruptions. it will not retranscode videos that have already been encoded.
  if ($base_name -match "\[$($sig)\]$") {
    $sig_found_base_name = $base_name -replace " \[$sig\]"
    $final_msg += "`n Signature found: $($base_name)"
    echo " Signature found: $($base_name)"
    continue
  }

  if ($base_name -eq $sig_found_base_name) {
    $final_msg += "`n Skiping: $($base_name)"
    echo "Skiping: $($base_name)"
    continue
  }

  # -hwaccel cuda $name -c:v hevc_nvenc -tune uhq -highbitdepth 1 -pix_fmt yuv420p10le -temporal-aq 1 -rc-lookahead 32 -spatial-aq 1 
  # -c:v libx265 -x265-params "crf=26:profile=main10:preset=slow" -pix_fmt yuv420p10le
  # -c:a acc
  # -pix_fmt p010le 
  # -cq 19-35 
  # -disposition:s:0 default -disposition:s:0 none
  ffmpeg -hwaccel cuda -i $name -c:v hevc_nvenc -tune uhq -disposition:s:0 default -highbitdepth 1 -pix_fmt yuv420p10le -temporal-aq 1 -rc-lookahead 32 -spatial-aq 1 -c:a copy -c:s copy -map 0 $tmp_name
  
  Rename-Item -LiteralPath "$tmp_name" -NewName $final_name
  $final_msg += "`n Finish Encoding: $($final_name)"
};
echo $final_msg
