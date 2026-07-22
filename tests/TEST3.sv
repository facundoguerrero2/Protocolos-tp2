integer taps_to_repeat = 65535;
integer taps_counter = 0;
integer i = 0; // para bucle
initial begin
    
    clock_en = 1;
    i_enable = 1;

    for(i=0; i<100; i=i+1)
    begin
        reset();
        taps_counter = 0;
        while(1) begin
            @(posedge clock);
            if(i_valid_monitor)
            begin
                taps_counter = taps_counter + 1;
            
                if(taps_counter == taps_to_repeat) begin
                    
                    #1;
                    if(LFSR !== SEED)
                    begin
                        $display("\n[!!!] ERROR no fue periodico en tiempo %0t [!!!]", $time);
                        $display("      Hardware dio: %h", LFSR);
                        $display("      Debia dar: %h", SEED);
                        $finish; 
                    end 
                    else begin
                        // Si todo va bien imprime el valor exitoso
                        $display("[PERIODICIDAD OK] Tiempo %0t | LFSR Out: %h | SEED: %h", $time, LFSR, SEED);
                        set_seed();
                        soft_reset();
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
