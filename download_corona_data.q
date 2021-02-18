
c:.opts.addopt[`;`debug;0b;"debug"];
c:.opts.addopt[c;`datapath;.file.makepath[`:/home/steve;"projects/coronavirus/data"];"data path"];
c:.opts.addopt[c;`data_api;"https://api.covidtracking.com";"link to data api"];
c:.opts.addopt[c;`countries_data_api;"https://corona-api.com/countries";"link to data api"];
c:.opts.addopt[c;`owid_data_api;"https://covid.ourworldindata.org/data";"link to data api"];
c:.opts.addopt[c;`regions;`us`states;"valid regions to query"];
c:.opts.addopt[c;`full_data;0b;"download all data, or just update"];
parms:.opts.get_opts c;
show parms;
  

null_empty_data:{[t;c] l:t c; t[c]:@[l;where 0<type each l;:;0Nf]; t};

download_owid_data:{[parms]  // from https://covid.ourworldindata.org/data/
  old_data:.file.get .file.makepath[parms[`datapath];`global_data];
  maxdate:exec max date from old_data;
  if[maxdate >= .z.D ;:old_data]; // only download max of once per day 
  hist:parms[`full_data] or maxdate < .z.D-1; // download full data if maxdate more than 1 day ago.
  url:parms[`owid_data_api];

  optdict:.dict.kvd(`version;$[hist;`;`latest];`filetype;$[hist;`data;`latest]);
  url:.string.append[parms[`owid_data_api];.string.format["/%version%/owid-covid-%filetype%.csv";optdict]];

  request:"curl -s \"",url,"\"";
  data:("SSSD",55#"F";1#csv)0: system request;
  data:.tbl.rename[data;`iso_code;`country];
  data:`date`country`population xcols $[`last_updated_date in cols data;.tbl.rename[data;`last_updated_date;`date];data];
  
  data:$[hist;data;0!select by date,country from old_data,data];
  .log.info "Saving country history to ",string .file.makepath[parms[`datapath];`global_data] set distinct `date`country xasc data; 
  data}

download_country_data:{[parms]
  optdict:.dict.kvd(`hist;$[parms[`full_data];`daily;`current]);
  url:parms[`countries_data_api];
  request:"curl -s \"",url,"\"";
  rawdata:.j.k first system request;
  rawdata:rawdata`data;
  rawdata:update `$name,`$code,"Z"$updated_at from rawdata;
  data:select country:name,country_code:code,population,updated_at from rawdata;
  latest:data,'delete calculated from rawdata`latest_data;
  latest:update date:`date$updated_at from latest;
  latest:select date,country,country_code,population,deaths,confirmed,recovered,updated_at from latest;
  hist:.file.get[histpath:.file.makepath[parms`datapath;"countries_history"]];
  .log.info "Saving country history to ",string histpath set distinct `date`country xasc hist,latest; 
  latest}

download_from_api:{[region;parms]
  optdict:.dict.kvd(`version;`v1;`region;region;`hist;$[parms[`full_data];`daily;`current]);
  url:.string.append[parms[`data_api];.string.format["/%version%/%region%/%hist%.csv";optdict]];
  /fmtstring:$[region~`us;"DIIIIIIIIIIIZIIIZIIIIIIIS";"DSIIIISIIIIIIIISZZZIIZIIIIIIIIIIII"];
  fmtstring:$[region~`us;"DIIIIIIIIIIZIIIZIIIIIIIIS";"DSIIIISIIIIIIIISZZZIIZIIIIIIIIIIII"];
  request:"curl -s \"",url,"\"";
  t:(fmtstring;1#csv)0: system request;
  t}

save_data:{[t;region;parms]
  t:t[region];
  outfile:.file.makepath[parms`datapath;region];
  t_orig:$[.file.exists[outfile];get outfile;()];
  result:0!?[(t_orig uj 0!t);();{x!x}$[region~`states;`date`state;`date,()];()]; 
  -1 "Saving data to ",string outfile set result;
  0b} 
    
  
main:{[parms]
  /country_data:download_country_data[parms];
  owid_data:download_owid_data[parms];
  raw_data:(parms`regions)!download_from_api[;parms] each parms[`regions];
  save_data[raw_data;;parms] each key raw_data;
  }

if[not parms[`debug];main[parms];exit 0];
