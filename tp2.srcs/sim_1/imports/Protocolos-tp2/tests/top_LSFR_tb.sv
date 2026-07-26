`default_nettype none
`timescale 1ns/1ns

module top_LSFR_tb();

    localparam PERIODO_CLK = 10;
    localparam SEED = 16'hFFFF;
    localparam NB_LSFR = 16;

    reg                     i_enable;
    reg                     i_rst;
    reg                     i_soft_reset;
    reg [NB_LSFR-1:0]       i_seed;
    reg                     clock;
    reg                     clock_en;  
   
    wire [NB_LSFR-1:0]        LFSR;
    wire                    i_valid; // cable interno que conecta el valid_generator con el top_LSFR


    
    // Parámetros y registros del generador de valid

    parameter MIN_WAIT = 1;  // Mínima cantidad de ciclos a esperar
    parameter MAX_WAIT = 10; // Máxima cantidad de ciclos a esperar
    parameter DEFAULT_WAIT_CYCLES = 1;
    reg [31:0] valid_wait_cycles = 1;  // Variable que guarda el tiempo de espera actual
    reg valid_random_cycles = 0; //flag para habilitar/deshabilitar la aleatoriedad en i_valid
    reg [31:0] valid_cicle_counter;      // Contador de ciclos
    reg valid_signal;            // señal para conectar al módulo

    assign i_valid = valid_signal;

    top_LSFR #(
        .SEED(SEED),
        .CYCLES(5)
    ) u_top_LSFR (
        .i_enable(i_enable),
        .i_rst(i_rst),
        .i_soft_reset(i_soft_reset),
        .i_seed(i_seed),
        .clock(clock),
        .o_LFSR(LFSR),
        .i_valid(i_valid)
    );

    
    
    initial
    begin
        clock   <= 'd0;
    end
    always #(PERIODO_CLK/2) if(clock_en) clock = ~clock;

    


    //----> Reset Asincrono
    task reset ();
        time reset_time;
        begin
            $display("Reset.");
            //----> Activo reset
            i_rst <= 'd1;

            //----> Randomizo duracion del reset
            reset_time = $urandom_range(1,249) * 1us;
            #reset_time;

            //----> Bajo reset de manera sincronica
            @(posedge clock); // esta linea sirve para esperar a que el clock haga un flanco positivo y luego levantar el reset

            //----> Bajo reset
            i_rst <= 'd0; 
        end
    endtask

    task soft_reset();
        time reset_time;
        begin
            $display("Soft Reset.");
           // i_seed = 16'hABCD;
            i_soft_reset = 1'b1;
            reset_time = $urandom_range(1,249) * 1us;
            #reset_time;
            @(posedge clock); // Esperamos 1 flanco de reloj
            #1;
            i_soft_reset = 1'b0; // Lo apagamos
        end
    endtask
    
    task set_seed();
        begin
            i_seed = $urandom_range(1, 2**NB_LSFR-1); //numero random de 16 bits para el puerto de seed
            #1; 
            $display("Puerto de Seed seteado a: %h", i_seed);
        end
    endtask

    `include "./valid_generator.sv"

    

    `define TEST3
        
    `ifdef TEST_RAND_GENERATING
        `include "./TEST_RAND_GENERATING.sv"
    `endif

    `ifdef TEST1
        
        `include "./TEST1.sv"
    `endif

    `ifdef TEST2
        `include "./TEST2.sv"
    `endif
    
     `ifdef TEST3
        `include "./TEST3.sv"
    `endif





endmodule
