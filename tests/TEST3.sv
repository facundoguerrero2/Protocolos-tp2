/**
Test simple de comportamiento esperado, para verificar que el checker funcione correctamente en condiciones normales.
20 iteraciones de reset, habilitación del LFSR, espera de tiempo random y habilitacion del checker, comparación de los valores generados con los esperados.
se comparan 50 valids por iteración, y se reporta el total de matches correctos al final de cada iteración.

se espera que el total de matches correctos sea igual a n-1 por cada iteracion, ya que el primero deberia ser MISMATCH porque es el dato que se toma como ancla para la proxima palabra.
a partir del segundo dato deberia ser siempre MATCH, ya que el checker deberia predecir correctamente el siguiente valor del LFSR.
*/


initial 
begin
    clock_en = 1;
    for(i=0; i<20; i=i+1)
    begin
        reset();
        i_gen_enable = ENABLE; 
        
        #($urandom_range(50,500) * 1ns);
        
        @(posedge clock);
        i_checker_enable = ENABLE; 
        $display("[%0t ns] Checker Habilitado", $time);
       
        monitor_valids(50, $sformatf("TEST 3 -ITERACION %0d", i));
        
        i_checker_enable = DISABLE;
        i_gen_enable = DISABLE;
    end
    $finish;
end 
