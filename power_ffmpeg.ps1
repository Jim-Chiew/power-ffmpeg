$encoding_prefix = '.tmp'
$sig = 'ffmpeg'
$sig_found_base_name = ''
$final_msg = '`n`nReport:'

foreach ($file in (ls | Sort-Object Name)){
  $extension = $file.Extension
  $base_name = $file.BaseName
  $name = $file.name
  $dir = $file.directoryName
  $tmp_name = "$($encoding_prefix) $($base_name) [$($sig)]$($extension)"  # Used when in process of encoding.
  $final_name = "$($base_name) [$($sig)]$($extension)"  # change tmp_name to final_name when done.

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

  ffmpeg -hwaccel cuda -i $name -c:v hevc_nvenc -map 0:v -map 0:a -map 0:s -c:a aac -c:s ass -disposition:s:0 default $tmp_name
  
  Rename-Item -LiteralPath "$tmp_name" -NewName $final_name
  $final_msg += "`n Finish Encoding: $($final_name)"
};
echo $final_msg
