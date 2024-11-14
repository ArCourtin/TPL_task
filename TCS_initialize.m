function TCS=TCS_initialize(COMport,params)
% baseline_temp in C
% COMport is a str designating the serial port to which the TCS is
% connected
disp('Initializing the TCS device. This may take a few seconds.')
TCS=serialport(COMport,115200,'Timeout', 1);
disp('Done');
writeline(TCS,'F'); 
bl_str=params.TCS.bl_str;
writeline(TCS,bl_str);
end