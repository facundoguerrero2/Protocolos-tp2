integer taps_to_repeat = 65535;
integer taps_counter = 0;
integer i = 0; // para bucle
reg [15:0] i_seed_siguiente;
initial begin
    
    clock_en = 1;
    i_enable = 1;
    
    for(i=0; i<100; i=i+1)
    
    begin

        set_seed();
        @(negedge clock);
        soft_reset();
        taps_counter = 0;
        i_seed_siguiente = {i_seed[14:0], i_seed[15]} ^ (i_seed[15] ? 16'h002C : 16'h0000);

        while(1) begin
            @(posedge clock);
            if(i_valid_monitor)
            begin
                taps_counter = taps_counter + 1;

                if(taps_counter == 1) begin
                    #1;
                    if(LFSR !== i_seed_siguiente) begin
                        $display("\n[!!!] ERROR: El LFSR quedó pegado en tiempo %0t [!!!]", $time);
                        $display("      Hardware dio: %h", LFSR);
                        $display("      Debia dar:  %h", i_seed_siguiente);
                        $finish;
                    end 
                    else begin
                        // Si arrancó bien, imprimimos pero NO hacemos break. Dejamos que siga contando.
                        $display("[PASO 1/65535 OK] Iteración %0d despego bien hacia: %h", i, LFSR);
                    end
                end


                if(taps_counter == taps_to_repeat) begin
                    
                    #1;
                    if(LFSR !== i_seed)
                    begin
                        $display("\n[!!!] ERROR no fue periodico en tiempo %0t [!!!]", $time);
                        $display("      Hardware dio: %h", LFSR);
                        $display("      Debia dar: %h", i_seed);
                        $finish; 
                    end 
                    else begin
                        // Si todo va bien imprime el valor exitoso
                        $display("[PASO 65535/65535] [PERIODICIDAD OK] Tiempo %0t | LFSR Out: %h | SEED: %h", $time, LFSR, i_seed);
                        
                        taps_counter = 0;
                        break;
                    end
                    
                    
                end

                
            end
            

        end
    end

    $display("--- PERIODICIDAD COMPLETADA CON ÉXITO ---");
    
    $finish;
end
