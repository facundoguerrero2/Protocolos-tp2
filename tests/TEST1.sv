/*
TEST1: Dejamos correr y probamos los reset, lo comparamos con un modelo behavioral que calcula el próximo estado del lfsr matematicamente.
*/
reg [15:0] expected_lfsr = SEED;

integer i=0; // para bucle
initial begin
    
    valid_random_cycles = 1; //seteamos la flag para que valid sea random
    for(i=0; i<100; i=i+1)
    begin
        // Inicializamos las señale
        clock_en = 1;
        i_enable = 1;
        @(posedge clock);
        #1;
        reset();

        #($urandom_range(50,500) * 1ns);
        set_seed();
        @(posedge clock);
        #1;
        soft_reset();

        #($urandom_range(50,500) * 1ns);


    end
    $display("Simulacion terminada sin errores.");
    $finish;
end


//BEHAVIORAL CHECKER
always @(posedge clock or posedge i_rst) begin
    
    if (i_rst) begin
        expected_lfsr = SEED;
    end 
    else if (i_soft_reset) begin
        expected_lfsr = i_seed;
    end 
    // Solo evaluamos si el enable está activo y si el cable interno w_valid manda el pulso
    else if (i_enable && i_valid) begin
        
        //  calculamos matematicamente cuál debería ser el próximo estado
        expected_lfsr = {expected_lfsr[14:0], expected_lfsr[15]} ^ (expected_lfsr[15] ? 16'h002C : 16'h0000);
        #1;
        
        // comparamos la salida real (lfsr) contra la matemática (expected_lfsr)
        if (o_lfsr !== expected_lfsr) begin
            $display("\n[!!!] ERROR en Tiempo %0t [!!!]", $time);
            $display("      Hardware dio: %h", o_lfsr);
            $display("      Matematica dio: %h", expected_lfsr);
            $finish; // Clava la simulación en la ventana de ondas justo donde falló
        end 
        else begin
            // Si todo va bien, imprimimos el valor exitoso (esto reemplaza a tu $monitor viejo)
            $display("[CHECK OK] Tiempo %0t | lfsr Out: %h", $time, o_lfsr);
        end
    end
end
