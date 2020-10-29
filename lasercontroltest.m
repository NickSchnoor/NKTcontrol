% Laser Automation Test
% For use to verify functions of NKTControl.m for SuperK Select
% Authored by Nick Schnoor 10/27/2020
% https://gitlab.com/rogerslab/

    %   COMMANDS TO TEST:
    % * connect/disconnect
    % * emissionOn/emissionOff
    % * resetInterlock
    % * getSuperKStatus
    % * getSelectStatus*
    % * getPowerLevel/setPowerLevel
    % * getSelectChannels**
    % * setSelectChannels**
    % * RFon/RFoff*
    % * SetSelectCrystalGains***
    % * getTimeout/setTimeout

    
%Commands IRL and in code                                                                           %What should happen
    
    
    
% Turn SuperK and Select Power on, turn interlock key, break interlock
% button, replace. Open Vis shutter, close NIR

laser=NKTControl                                                                                    % Initiate Laser Module
laser.connect(), pause()                                                                       % "Laser Connected"
output=laser.getSuperKStatus(); pause()                                                               % "Emission off" "Interlock needs Resetting", Front display should have reset interlocl
if output(2)~=0
    laser.resetInterlock(), pause()                                                            % Front display of SuperK should not have reset interlock
end
laser.getSelectStatus(), pause()                                                               % "Select emission off" "Vis shutter open" "NIR shutter closed" "RF off" "Crystal Temperature"
laser.emissionOn(), pause()                                                                    % *Whir*
laser.getSuperKStatus(), pause()                                                               % "Emission on" "Interlock off", Front display should not have reset interlock
laser.getSelectStatus(), pause()                                                               % "Select emission off" "Vis shutter open" "NIR shutter closed" "RF off" "Crystal Temperature"
laser.emissionOff(),pause()                                                                    % *Whir Stops*
laser.RFon(), pause()                                                                          % *other whir*
laser.getSuperKStatus(), pause()                                                               % "Emission off" "Interlock off", Front display should not have reset interlock
laser.getSelectStatus(), pause()                                                               % "Select emission off" "Vis shutter open" "NIR shutter closed" "RF on" "Crystal Temperature"
laser.emissionOn(), pause()                                                                    % *Whir and light*
% close vis shutter
laser.getSelectStatus(), pause()                                                               % "Select emission on" "Vis shutter closed" "NIR shutter closed" "RF on" "Crstal Temperature"
% open vis shutter
power=laser.getPowerLevel(), pause()                                                           % "power=##%" ## matches SuperK display 
to=laser.getTimeout(), pause()                                                                 % "to=0.05" looking for no errors
laser.setTimeout(to+0.010), pause()                                                            % looking for errors
laser.getTimeout(), pause()                                                                    % "to=0.15"
laser.getSelectChannels(), pause()                                                             % 3x8 matrix. Will be interesting to see what's in it. rows: wl, power, gain 
laser.RFon(), pause()                                                                          % *Whiiirrrrrr*
laser.emissionOn(), pause()                                                                    % *Whiiirrrrrr*+ooh shiny light
laser.getSuperKStatus(), pause()                                                               % "Emission on" "Interlock Off", Front display should not have reset interlocl
laser.getSelectStatus(), pause()                                                               % "Select emission on" "Vis shutter open" "NIR shutter closed" "RF on" "Crystal Temperature"
laser.setPowerLevel(power+15), pause()                                                        % More whirring, brighter light
laser.emissionOff(), pause()                                                                   % Light off
laser.emissionOn(), pause()                                                                    % Light on
laser.setSelectChannels([1,2,3],[550,650,450],[100,100,100],[1,1,0]), pause()                 % Pretty colors
wl=laser.getSelectChannels(), pause()                                                          % 3x8 matrix
laser.setSelectChannels([1,2,3],[wl(1:3)+50],[100,100,100],[1,1,0]), pause()                  % Different pretty colors
laser.setSelectChannels([1,2,3],[3000,700,500],[100,0,0],[1,0,0]), pause()                    % Expect some kind of wavelength exceeding error
laser.RFoff(), laser.emissionOff()                                                        % Light off
laser.disconnect()                                                                             % "Laser Disconnected"