reg [15:0] expected_LFSR = SEED;

integer i=0; // para bucle
initial begin
    
    
    for(i=0; i<100; i=i+1)
    begin
        // Inicializamos las señale
        clock_en = 1;
        i_enable = 1;
        @(negedge clock);
        reset();

        #($urandom_range(50,500) * 1ns);
        set_seed();
        @(negedge clock);
        soft_reset();

        #($urandom_range(50,500) * 1ns);


    end
    $display("Simulacion terminada sin errores.");
    $finish;
end


//BEHAVIORAL CHECKER
always @(posedge clock or posedge i_rst) begin
    
    if (i_rst) begin
        expected_LFSR = SEED;
    end 
    else if (i_soft_reset) begin
        expected_LFSR = i_seed;
    end 
    // Solo evaluamos si el enable está activo y si el cable interno w_valid manda el pulso
    else if (i_enable && i_valid_monitor) begin
        
        //  calculamos matematicamente cuál debería ser el próximo estado
        expected_LFSR = {expected_LFSR[14:0], expected_LFSR[15]} ^ (expected_LFSR[15] ? 16'h002C : 16'h0000);
        #1;
        
        // comparamos la salida real (LFSR) contra la matemática (expected_LFSR)
        if (LFSR !== expected_LFSR) begin
            $display("\n[!!!] ERROR en Tiempo %0t [!!!]", $time);
            $display("      Hardware dio: %h", LFSR);
            $display("      Matematica dio: %h", expected_LFSR);
            $finish; // Clava la simulación en la ventana de ondas justo donde falló
        end 
        else begin
            // Si todo va bien, imprimimos el valor exitoso (esto reemplaza a tu $monitor viejo)
            $display("[CHECK OK] Tiempo %0t | LFSR Out: %h", $time, LFSR);
        end
    end
end


always @(negedge clock) begin
    
    force u_top_LSFR.i_valid = $urandom_range(0, 1);

end
    