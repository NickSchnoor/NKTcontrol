% Laser Automation Test
% For use to verify functions of NKTControl.m for SuperK Select
% Authored by Nick Schnoor 10/27/2020
% https://gitlab.com/rogerslab/

    %   COMMANDS TO TEST:
    % * connect/disconnect
    % * emissionOn/emissionOff
    % * resetInterlock
    % * getSuperKStatus
    % * getSelectStatus
    % * getPowerLevel/setPowerLevel
    % * getSelectChannels/setSelectChannels
    % * RFon/RFoff
    % * getTimeout/setTimeout

    
%Commands IRL and in code                                                  % What should happen
    
% Turn SuperK on, turn interlock key
% Do not reset interlock--to be tested in code.
% Open Vis shutter, close NIR shutter
laser=NKTControl                                                                       
laser.connect();                                                           % "Laser Connected"
output=laser.getSuperKStatus();                                            % "Emission off" "Interlock needs Resetting", Front display should have reset interlock still
if output(2)~=0
    laser.resetInterlock(), pause()                                        % Front display of SuperK should not have reset interlock
end
laser.getSelectStatus(); pause()                                           % "Vis shutter open" "NIR shutter closed" "RF off" "Crystal Temperature=..."
laser.emissionOn()                                                         % *Whir*
laser.RFon(), setSelectChannels(1,550,100), pause()                        % *other whir*, laser comes on (makes sure at least one of the channels is on
laser.getSuperKStatus(), pause()                                           % "Emission on" "Interlock off"
laser.getSelectStatus(), pause()                                           % "Vis shutter open" "NIR shutter closed" "RF on" "Crystal Temperature=..."
power=laser.getPowerLevel()                                                % "power=..." matches SuperK display 
to=laser.getTimeout()                                                      % "to=0.05"
laser.setTimeout(to+0.010);                                                
laser.getSelectChannels(), pause()                                         % 3x8 matrix. Know channel 1. rows: channels [1:8], wavelengths [550,...], powers [100,...] 
laser.setPowerLevel(power+15), pause()                                     % More whirring, brighter light
laser.setSelectChannels(...
    [1:8],[550,650,450,551:555],[100,50,75,0,0,0,0,0]); pause()            % Laser color changes. Mix of red, green, blue
wl=laser.getSelectChannels(); pause()                                      % 3x8 matrix. rows: [1:8]; [550,650,450,551:555]; [100,50,75,0,0,0,0,0]
laser.RFoff(), laser.emissionOff()                                         % Laser turns off
laser.disconnect()                                                         % "Laser Disconnected"