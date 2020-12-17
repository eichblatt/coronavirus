
c:.opts.addopt[`;`debug;0b;"debug"];
c:.opts.addopt[c;`datapath;.file.makepath[`:/home/steve;"projects/coronavirus/data"];"data path"];
c:.opts.addopt[c;`data_api;"https://api.covidtracking.com";"link to data api"];
c:.opts.addopt[c;`regions;`us`states;"valid regions to query"];
c:.opts.addopt[c;`full_data;1b;"download all data, or just update"];
parms:.opts.get_opts c;
show parms;

download_from_api:{[region;parms]
  optdict:.dict.kvd(`version;`v1;`region;region;`hist;$[parms[`full_data];`daily;`current]);
  url:.string.append[parms[`data_api];.string.format["/%version%/%region%/%hist%.csv";optdict]];
  fmtstring:$[region~`us;"DIIIIIIIIIIIZIIIZIIIIIIIS";"DSIIIISIIIIIIIISZZZIIZIIIIIIIIIIII"];
  request:"curl -s \"",url,"\"";
  t:(fmtstring;1#csv)0: system request;
  t}

save_data:{[t;region;parms]
  t:t[region];
  outfile:.file.makepath[parms`datapath;region];
  t_orig:$[.file.exists[outfile];get outfile;()];
  result:0!?[t_orig,t;();{x!x}$[region~`states;`date`state;`date,()];()]; 
  -1 "Saving data to ",string outfile set result;
  0b} 
    
  
main:{[parms]
  raw_data:(parms`regions)!download_from_api[;parms] each parms[`regions];
  save_data[raw_data;;parms] each key raw_data;
  }

if[not parms[`debug];main[parms];exit 0];
