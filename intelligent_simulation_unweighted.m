clear

load('campus_simulation.mat');
G = graph(A_matrix,{'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','BS','aa','bb','cc','dd','ee','ff','gg','hh','ii','jj','kk','ll'});

% Update our battery capacity
battery_capacity = 500; % Amp hours

% I originally thought about using a very thorough model from class
% But for now let's start simple
% P_te = 10; % power consumed by transmitter (dBm)
% P_re = 10; % power consumed by reciever (dBm)
% P_o = 0; % output power of transmitter (dBm)
% T_on = 1; % transmitter 'on' time (ms)
% R_on = 100; % reciever 'on' time (ms)
% T_st = 10; % start-up time for transmitter (ms)
% R_st = 10; % start-up time for reciever (ms)
N_t = 1; % number of times transmitter is turned on
N_r = 1; % number of times reciever is turned on
E_compute = 1e-9; % pJ/bit to compute
E_rec = 11e-9; % pJ/bit to recieve
E_trans = 21e-9; % pJ/bit/m^2 to transmit
message_size = 64; % in bits!
E_write = 0;
E_read = 0;
wifi_bits = 14*8 + 20*8 + 8*8 + message_size; % ethernet + ip + udp + data
days = 0;

power_left(1:39, 1) = battery_capacity;
power_left(27, 1) = inf;


[TR, D]=shortestpathtree(G,'all','BS','method','unweighted');
figure;
plot(TR)
title('Unweighted')
DD = D;
DD(1,27) = Inf;

% repeat as long as some node can reach the BS
while ~min(isinf(DD)) 
    while all(power_left >= 0)
        days = days + 1;
        for i=1:size(TR.Nodes) % simulate all nodes
            num_pred = 0;
            for j=1:39 % find the number of times we have to retransmit
                if j ~= i
                    [P, d] = shortestpath(TR,j,i);
                    if d ~= inf
                        num_pred = num_pred + 1; % increment the number of predecessors
                    end
                end
            end
            N_r = num_pred;
            N_t = num_pred + 1;
            
            % Calculate the total power usage for communication
            % Complex model
            % E_c = N_t*(P_te*(T_on+T_st)+P_o*T_on) + N_r*(P_re*(R_on+R_st));
            
            % Simple model
            % power used = power to process own sample + N_t * power to transmit + 
            % N_r * power to recive
            message_size = N_t * 8;
            new_wifi_bits = 14*8 + 20*8 + 8*8 + message_size; % ethernet + ip + udp + data
            E_used = E_compute*wifi_bits + (E_compute*new_wifi_bits+E_trans*new_wifi_bits*874225/(3.281^2)) + E_rec*(new_wifi_bits - 64);
            E_write = N_r * E_compute * 64;
            E_read =  N_r * E_compute * 64;
            power_left(i,1) = power_left(i,1) - E_used - E_read - E_write;
        end
    end
    dead = find(power_left<0);
    disp('Day node died:')
    disp(days)
    power_left(dead,1) = inf; % we already removed this...
    A_matrix(dead,1:end)=0;
    A_matrix(1:end,dead)=0;
    G = graph(A_matrix,{'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','BS','aa','bb','cc','dd','ee','ff','gg','hh','ii','jj','kk','ll'});

    [TR, D] = shortestpathtree(G,'all','BS','method','unweighted');
    DD = D;
    DD(1,27) = Inf;
    figure;
    plot(TR)
    title('Unweighted')
end