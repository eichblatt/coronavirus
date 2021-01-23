c:.opts.addopt[`;`debug;1b;"debug"];
c:.opts.addopt[c;`hist_path;.file.makepath[getenv`HOME;"projects/coronavirus/data/countries_timeline.json"];"data file path"];
c:.opts.addopt[c;`curr_path;.file.makepath[getenv`HOME;"projects/coronavirus/data/countries.json"];"current data file path"];
c:.opts.addopt[c;`outpath;.file.makepath[getenv`HOME;"projects/coronavirus/data/countries_history"];"output file path"];
parms:.opts.get_opts c;
system "c 23 230"

// this data was downloaded using the API https://corona-api.com/countries?include=timeline

load_history:{[parms]
  rawdata:first read0 parms[`hist_path];
  rawdata:.j.k[rawdata]`data; 
  rawdata:update `$name,`$code,"Z"$updated_at from rawdata;
  data:select country:name,country_code:code,population,last_update:updated_at from rawdata;
  histories:raze {tl:1_x`timeline;$[count[tl]>0;`country xcols update country:x`name,"Z"$updated_at,"D"$date from tl;()]}each rawdata;
  histories:histories lj 1!delete last_update from data; 
  histories:`date`country xasc select date,country,country_code,population,deaths,confirmed,recovered,updated_at from histories;
  .log.info "Saving output file to ",string parms[`outpath] set histories;
  }

load_latest:{[parms]
  rawdata:first read0 parms[`curr_path];
  rawdata:.j.k[rawdata]`data;
  rawdata:update `$name,`$code,"Z"$updated_at from rawdata;
  data:select country:name,country_code:code,population,updated_at from rawdata;
  latest:data,'delete calculated from rawdata`latest_data;
  latest:update date:`date$updated_at from latest;
  latest:select date,country,country_code,population,deaths,confirmed,recovered,updated_at from latest;
  latest}
 
main:{[parms]
  load_history[parms];
  latest:load_latest[parms];
  hist:.file.get[parms`outpath];
  hist:hist,latest;
  .log.info "Saving hist + latest to ",string parms[`outpath] set hist;
  }

if[not parms[`debug];main[parms];exit 0];
