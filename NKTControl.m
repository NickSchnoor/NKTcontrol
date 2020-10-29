classdef NKTControl < handle
    %NKTControl Class to control super continuum (SuperK) lasers from NKT.
    %
    % This class uses the serial communication (virtually through a USB
    % connection) to communicate with NKT SuperK Extreme products and may
    % potentially work for similar systems as well. All code is tested on
    % a SuperK Extreme EXU-6.
    %Can obtain and change the power level and upper/lower bandwidths, turn
    %emission on or off, and reset the interlock.
    %
    %Methods:
    % * connect/disconnect
    % * getTimeout/setTimeout    
    % * resetInterlock    
    % * emissionOn/emissionOff
    % * RFon/RFoff
    % * getSuperKStatus
    % * getSelectStatus
    % * getPowerLevel/setPowerLevel
    % * getSelectChannels/setSelectChannels**             all messed up

    %
    % Todo:
    % * Make all to disp-status commands "disablable"!
    % * addrLaser, addrVaria and host are at the moment hardcoded and hidden to the user
    % * make documentation nicer (type docNKTControl)
    % * https://uk.mathworks.com/help/matlab/matlab_prog/add-help-for-your-program.html
    %
    % Examples:
    %   to come
    %
    % Authors: Jess Rigley and Villads Egede Johansen (University of Cambridge)
    % Contact: vej22@cam.ac.uk
    % Webpage: http://www.ch.cam.ac.uk/group/vignolini
    % Git repo: https://github.com/villadsegede/NKTcontrol.git
    % Version: 1.0
    % Date: 21/08-2017
    % Copyright: MIT License (see github page)
    
    
    
    % Adopted for RF Driver & SuperK Select AOTF combo by: Nick Schnoor
    % University of Wisconsin
    % nschnoor@wisc.edu
    % https://gitlab.com/rogerslab/matlab
    % 10/26/2020
    
    
    properties
        timeout=0.05; %Timeout in seconds for the serial port.
    end
    properties (Access=private)
        s;      %Serial communication object.
    end
    
    methods
        %Public methods
        function [] = connect(obj)
            % connect Connects to the laser.
            %
            % Detects which serial ports are available and tries to connect
            % to each in turn until the laser is connected. Always first
            % method to be called.
            %
            % see also: disconnect
            
            warning off MATLAB:serial:fread:unsuccessfulRead;
            %Find serial ports
            serialInfo = instrhwinfo('serial');
            ports=serialInfo.AvailableSerialPorts;
            for n=1:length(ports)
                obj.s=serial(ports(n),'BaudRate',115200,'Timeout',obj.timeout);
                fopen(obj.s);
                data='30';
                % Send telegram to laser and see if it replies.
                %If there is a reply starting with '0A' the laser is connected.
                obj.sendTelegram(obj.addrLaser,obj.msgRead,data);
                out=dec2hex(fread(obj.s,9),2);
                if isempty(out)==1
                    fclose(obj.s);
                    delete(obj.s);
                    clear obj.s
                    continue
                elseif out(1,:)==obj.startTel
                    disp('Laser connected');
                    break
                else
                    fclose(obj.s);
                    delete(obj.s);
                    clear obj.s
                    continue
                end
            end
            warning on MATLAB:serial:fread:unsuccessfulRead
        end
        
        
        function [] = disconnect(obj)
            % disconnect Close serial port connection thus disconnecting
            % laser.
            %
            % see also: connect
            
            fclose(obj.s);
            delete(obj.s);
            clear obj.s
            disp('Laser disconnected');
        end
        
        
        function timeout = getTimeout(obj)
            %getTimeout Obtains the timeout for the serial port in seconds.
            %
            % Return:
            %  timeout Current timeout value given in seconds.
            %
            % see also: setTimeout
            
            timeout=obj.timeout;
        end

        
        function [] = setTimeout(obj,timeout)
            %setTimeout Sets the timeout for the serial port in seconds.
            %
            % This function may be useful to play around with if either
            % communication fails or faster updates are required.
            % Input:
            %  timeout timeout value given in second.
            %
            % see also: getTimeout
            
            
            obj.timeout=timeout;
        end
        
        
        function [] = resetInterlock(obj)
            %resetInterlock Resets the interlock circuit.
            
            data=['32'; '01'];
            obj.sendTelegram(obj.addrLaser,obj.msgWrite,data);
            obj.getTelegram(8);
        end
        
        
        function [] = emissionOn(obj)
            % emissionOn Turns emission on.
            %
            % see also: emissionOff
            
            data=['30'; '03'];
            obj.sendTelegram(obj.addrLaser,obj.msgWrite,data);
            obj.getTelegram(8);
        end
        
        
        function [] = emissionOff(obj)
            % emissionOff Turns emission off.
            %
            % see also: emissionOn
            
            data=['30'; '00'];
            obj.sendTelegram(obj.addrLaser,obj.msgWrite,data);
            obj.getTelegram(8);
        end
        
                
        function []=RFon(obj)
            data=['30'; '01'];
            obj.sendTelegram(obj.addrRF,obj.msgWrite,data);
            obj.getTelegram(8);
        end

        
        function []=RFoff(obj)
            data=['30'; '00'];
            obj.sendTelegram(obj.addrRF,obj.msgWrite,data);
            obj.getTelegram(8);
        end
        
        
        function output = getSuperKStatus(obj)
            %getStatus Obtains the status of the laser.
            %
            % Checks whether the serial port is open, whether emission is on
            % or off, and whether the interlock needs resetting.
            %
            % Return:
            %   output  Status bits about emission and interlock.
            %            bit 1: Emission 0/1 is off/on;
            %            bit 2: Interlock 0/1 is on/off;
            
            % See Also: getSelectStatus
            
            
            data='66';
            obj.sendTelegram(obj.addrLaser,obj.msgRead,data);
            out=obj.getTelegram(10);
            hexdata=[out(7,:) out(6,:)];
            decdata=hex2dec(hexdata);
            status=dec2bin(decdata,16);
            output=[status(16), status(15)];
            disp(['Com port ' obj.s.status]);
            if status(16)=='1'
                disp('Emission on');
            else
                disp('Emission off');
            end
            if status(15)=='0'
                disp('Interlock off');
            else
                disp('Interlock needs resetting');
            end
        end
        
        
        function output = getSelectStatus(obj)
            % getSelectStatus Obtains serial info about shutters, emission
            %
            %   Return:
            %       output  Status bits for emission, shutters, RF power
            %               and Crystal temperature
            %               bit 1: Emission 0/1 is off/on
            %               bit 2: Vis Shutter 0/1 is open/closed
            %               bit 3: NIR Shutter 0/1 is open/closed
            %               bit 4: RF Power 0/1 is off/on
            %               bit 5: Crystal Temperature should be between
            %                      18-28 degrees C
            %
            % See also: getSuperKStatus, getSelectChannels
            
            data='66';
            obj.sendTelegram(obj.addrSelect,obj.msgRead,data);
            out=obj.getTelegram(10);
            decdata=hex2dec(out);
            shutter=dec2bin(decdata(7),2);
%             if decdata(10)==10
%                 disp('Select Emission On')
%             else
%                 disp('Select Emission Off')
%             end
            if str2double(shutter(2))==0
                disp('Vis Shutter Closed')
            else
                disp('Vis Shutter Open')
            end
            if str2double(shutter(1))==0
                disp('NIR Shutter Closed')
            else
                disp('NIR Shuter Open')
            end
            data='30';
            obj.sendTelegram(obj.addrSelect,obj.msgRead,data);
            out=obj.getTelegram(9);
            RF=base2dec(out(6,:),16);
            if dec2bin(RF)=='1'
                disp('RF on')
            else
                disp('RF off')
            end
            data='38';
            obj.sendTelegram(obj.addrRF,obj.msgRead,data);
            out=obj.getTelegram(10);
            temp=0.1*hex2dec([out(7,:), out(6,:)]);%convert units to C
            disp(['Crystal Temperature = ',num2str(temp),' degrees C'])
            output=[%decdata(10),...
                str2double(shutter(2)),str2double(shutter(1)),RF,temp]; 
        end
        
        
        function powerLevel = getPowerLevel(obj)
            % getPowerLevel Obtain power level
            %
            % Return:
            %   powerLevel  Power level given in percent
            %
            % see also: setPowerLevel
            
            data='37';
            obj.sendTelegram(obj.addrLaser,obj.msgRead,data);
            out=obj.getTelegram(10);
            %obtain hex power level from telegram
            hexPowerLevel=[out(7,:) out(6,:)];
            powerLevel=0.1*hex2dec(hexPowerLevel);%convert units to percent
        end
        
        
        function [] = setPowerLevel(obj,powerLevel)
            
            % setPowerLevel Set power level
            %
            % Input:
            %   powerLevel  Desired power level 
            %               from 0 to 100% by 0.1%
            %
            % see also: getPowerLevel
            
            powerLevel2=10*powerLevel; %convert units to 0.1%
            %convert power level to two bytes
            hexPowerLevel=dec2hex(powerLevel2,4);
            hexPowerLevel1=hexPowerLevel(1:2);
            hexPowerLevel2=hexPowerLevel(3:4);
            data=['37'; hexPowerLevel2; hexPowerLevel1];
            obj.sendTelegram(obj.addrLaser,obj.msgWrite,data);
            obj.getTelegram(8);
        end
        
        
        function [wl,amplitude]=getSelectChannels(obj)
            % getSelectChannels Obtains the wavelengths, powers, and on/off status
            % of each channel of the Select filter.
            %
            % Return:
            %    wl     List of wavelengths from the 8 channels
            %    amplitude  List of powers from the 8 channels
            %
            % Output:
            %   3x8 matrix with channel numbers, wavelengths, powers, gains
            %
            % See also: setSelectChannels
            
            
            wl=zeros(1,8);
            amplitude=zeros(1,8);
            % gain=zeros(1,8);
            for channel=0:7
                
                data=['9',num2str(channel)];
                obj.sendTelegram(obj.addrRF,obj.msgRead,data);
                out=obj.getTelegram(24);
                hexwl=[out(8,:),out(7,:),out(6,:)];
                wl(channel+1)=hex2dec(hexwl)/1000;
                
                data=['B',num2str(channel)];
                obj.sendTelegram(obj.addrRF,obj.msgRead,data);
                out=obj.getTelegram(12);
                hexPower=[out(7,:) out(6,:)];
                amplitude(channel+1)=0.1*hex2dec(hexPower);%convert to percent
%                 
%                 data=['C',num2str(channel)];
%                 obj.sendTelegram(obj.addrRF,obj.msgRead,data);
%                 out=obj.getTelegram(10);
%                 hexGain=[out(7,:) out(6,:)];
%                 gain(channel+1)=0.1*hex2dec(hexGain);%convert units to percent
            end
            disp([1:8;wl;amplitude]) %;gain])
        end
                
        
        function []=setSelectChannels(obj,channel,wavelength,amplitude)
            % setSelectChannel allows for manipulation of wavelength
            % channels---multiple at once!
            
            % Inputs:
            %   channel     Which channels to be changed
            %               from 1 to 8
            %   wavelength  What to change those channels' wavelengths to
            %               from 400 to 2000 by 0.001 nm
            %   amplitude       What power to change those channel to
            %               from 0 to 100% by 0.1%
            %
            % See also: getSelectChannels
            
            if isequal(size(channel),size(wavelength),size(amplitude))==1
                for n=1:length(channel)
                    
                    hexwl=dec2hex(round(wavelength(n),3)*1000,6);
                    data=['9',num2str(channel(n)-1); hexwl(5:6); hexwl(3:4); hexwl(1:2)];
                    obj.sendTelegram(obj.addrRF,obj.msgWrite,data);
                    obj.getTelegram(8);
                    
                    hexPower=dec2hex(round(amplitude(n),1)*10,4);
                    data=['B',num2str(channel(n)-1);hexPower(3:4);hexPower(1:2)];
                    obj.sendTelegram(obj.addrRF,obj.msgWrite,data);
                    obj.getTelegram(8);
                end               
            else
                disp('Error: Invalid Input Vector Sizes. Make sure all inputs have same size.')
            end
        end
        
        
    end
    
    
    % Private methods
    methods(Access=private)
        function [] = sendTelegram(obj,address,msgType,data)
            % sendTelegram sends a telegram to the laser
            %
            % Info on communication protocol to be found in documentation
            % for SuperK laser.
            %
            % Input:
            %  address  Address of the laser (16 bit)
            %  msgType  Type of message (16 bit)
            %  data     Data - if applicable
            %
            %(once again, see NKT SuperK documentation for details!)
            %
            % seeAlso: getTelegram
            
            message=[address; obj.host; msgType; data];
            crc=obj.crcValue(message);
            crc1=crc(1:2);
            crc2=crc(3:4);
            t=[obj.startTel; address; obj.host; msgType; data; crc1; crc2; obj.endTel];
            out(1,:)=obj.startTel;%start of transmission
            %replace special characters. m counts number of special
            %characters as this shifts subsequent rows of the array
            m=0;
            for n=2:(length(t)-1)
                if t(n,:)=='0A'
                    out(n+m:n+m+1,:)=['5E'; '4A'];
                    m=m+1;
                elseif t(n,:)=='0D'
                    out(n+m:n+m+1,:)=['5E'; '4D'];
                    m=m+1;
                elseif t(n,:)=='5E'
                    out(n+m:n+m+1,:)=['5E'; '9E'];
                    m=m+1;
                else
                    out(n+m,:)=t(n,:);
                end
            end
            out(length(out)+1,:)=obj.endTel;%end of transmission
            fwrite(obj.s,hex2dec(out),'uint8'); %send to laser
        end
        
        
        function out = getTelegram(obj,size)
            %getTelegram Receives a telegram from the laser.
            %
            % Info on communication protocol to be found in documentation
            % for SuperK laser.
            %
            % Input:
            %  Size  The expected length of the received telegram.
            %
            % seeAlso sendTelegram
            
            received=fread(obj.s,size);
            %replace any special characters in the telegram. m counts the number of special
            %characters as this shifts the subsequent rows of the array
            t=dec2hex(received,2);%telegram in hexadecimal
            m=0;
            n=1;
            while n<=length(t)
                if t(n,:)=='5E'
                    if t(n+1,:)=='4A'
                        out(n-m,:)='0A';
                    elseif t(n+1,:)=='4D'
                        out(n-m,:)='0D';
                    elseif t(n+1,:)=='9E'
                        out(n-m,:)='5E';
                    end
                    m=m+1;
                    n=n+2;
                else
                    out(n-m,:)=t(n,:);
                    n=n+1;
                end
            end
            %check if transmission is complete and receive any additional
            %bytes if necessary
            while out(length(out),:)~=obj.endTel
                out(length(out)+1,:)=dec2hex(fread(obj.s,1),2);
            end
        end
        
        function crc = crcValue(obj,message)
            %crcValue Finds the CRC value of a given message
            %
            % Info on communication protocol to be found in documentation
            % for SuperK laser. CRC value found through look-up table.
            %
            % Input:
            %  message  Data for which CRC value needs to be found.
            %
            % Return:
            %  crc  The corresponding CRC value.
            %
            % seeAlso: sendTelegram
            
            data=hex2dec(message);
            
            ui16RetCRC16 = hex2dec('0');
            for I=1:length(data)
                ui8LookupTableIndex = bitxor(data(I),uint8(bitshift(ui16RetCRC16,-8)));
                ui16RetCRC16 = bitxor(obj.Crc_ui16LookupTable(double(ui8LookupTableIndex)+1),mod(bitshift(ui16RetCRC16,8),65536));
            end
            crc=dec2hex(ui16RetCRC16,4);
        end
    end
    
    
    properties(Constant, Access=private)
        %Bytes for the start and end of telegrams and the addresses of the
        %laser, varia, and host.
        
        %Start of telegram
        startTel='0D';
        %End of telegram
        endTel='0A';
        %Laser address
        addrLaser='0F';
        %RF Address
        addrRF='10';
        %Select address: value of address switch on Select +10
        addrSelect='11';
        %Host Host address: can be anything greater than 160 (A0)
        host='A2';
        %Message type = read
        msgRead='04';
        %Message type = write
        msgWrite='05';
        %CRC look up table
        Crc_ui16LookupTable=[0,4129,8258,12387,16516,20645,24774,28903,33032,37161,41290,45419,49548,...
            53677,57806,61935,4657,528,12915,8786,21173,17044,29431,25302,37689,33560,45947,41818,54205,...
            50076,62463,58334,9314,13379,1056,5121,25830,29895,17572,21637,42346,46411,34088,38153,58862,...
            62927,50604,54669,13907,9842,5649,1584,30423,26358,22165,18100,46939,42874,38681,34616,63455,...
            59390,55197,51132,18628,22757,26758,30887,2112,6241,10242,14371,51660,55789,59790,63919,35144,...
            39273,43274,47403,23285,19156,31415,27286,6769,2640,14899,10770,56317,52188,64447,60318,39801,...
            35672,47931,43802,27814,31879,19684,23749,11298,15363,3168,7233,60846,64911,52716,56781,44330,...
            48395,36200,40265,32407,28342,24277,20212,15891,11826,7761,3696,65439,61374,57309,53244,48923,...
            44858,40793,36728,37256,33193,45514,41451,53516,49453,61774,57711,4224,161,12482,8419,20484,...
            16421,28742,24679,33721,37784,41979,46042,49981,54044,58239,62302,689,4752,8947,13010,16949,...
            21012,25207,29270,46570,42443,38312,34185,62830,58703,54572,50445,13538,9411,5280,1153,29798,...
            25671,21540,17413,42971,47098,34713,38840,59231,63358,50973,55100,9939,14066,1681,5808,26199,...
            30326,17941,22068,55628,51565,63758,59695,39368,35305,47498,43435,22596,18533,30726,26663,6336,...
            2273,14466,10403,52093,56156,60223,64286,35833,39896,43963,48026,19061,23124,27191,31254,2801,6864,...
            10931,14994,64814,60687,56684,52557,48554,44427,40424,36297,31782,27655,23652,19525,15522,11395,...
            7392,3265,61215,65342,53085,57212,44955,49082,36825,40952,28183,32310,20053,24180,11923,16050,3793,7920];
        
    end
end