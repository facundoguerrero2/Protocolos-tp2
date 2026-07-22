
initial begin
   
    // Inicializamos las señale
    clock_en = 1;
    i_enable = 1;
    reset();
    


    // Dejamos correr la simulación un rato para ver los números aleatorios
    #1000;
    #3000;

    // Pausamos el LFSR para probar el enable
    
    @(negedge clock);
    soft_reset();

    #300;

    clock_en = 0;
    #50;
    // Fin de la simulación
    $display("Simulacion terminada.");
    $finish;
end


// Monitor para ver en consola
integer iteration = 0;


always @(posedge clock) begin
    iteration <= iteration + 1;
end


initial begin
    $monitor("[It:%0d] Tiempo: %0t | Reset: %b | Enable: %b | LFSR Out: %h", 
                iteration, $time, i_rst, i_enable, LFSR);
end
