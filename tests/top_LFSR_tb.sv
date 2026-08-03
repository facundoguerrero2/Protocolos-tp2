`default_nettype none
`timescale 1ns/1ns
module top_lfsr_tb();

    // =========================================================================
    // 1. COMUNES
    // =========================================================================
    localparam PERIODO_CLK = 10;
    localparam NB_LFSR     = 16;
    localparam ENABLE      = 1'b1;
    localparam DISABLE     = 1'b0;
    reg                     clock;
    reg                     clock_en;  
    reg                     i_rst;

    // =========================================================================
    // 2. GENERADOR 
    // =========================================================================
    localparam SEED = 16'hFFFF;
    
    reg                     i_gen_enable;
    reg                     i_soft_reset;
    reg [NB_LFSR-1:0]       i_seed;          // Declarado (faltaba en tu bloque de señales)
    wire                    i_gen_valid;         // Conectado al generador de valid

    // ----> Salidas
    wire [NB_LFSR-1:0]      o_lfsr;            // Salida de datos LFSR del top
    wire                    o_gen_valid;     // Salida valid del generador


    // =========================================================================
    // 3. CHECKER (Control y Estado)
    // =========================================================================
    localparam LOCK_THR   = 5; //cuantos datos buenos consecutivos se necesitan para que el checker se lockee
    localparam UNLOCK_THR = 3; //cuantos datos malos consecutivos se necesitan para que el checker se desbloquee
    // ----> Inputs 
    reg                    i_checker_enable; // Cable que conecta al checker del top
    reg                    i_rst_checker;    // Reset del checker
    // ----> Outputs 
    wire [NB_LFSR-1:0]      o_checker;       // Salida de datos del checker
    wire                    o_lock;         // Salida de lock del checker

    wire [15:0] i_checker_data;  assign i_checker_data = queue_data_out; // Conectamos la salida de datos de la cola al puerto de entrada del checker
    wire        i_checker_valid; assign i_checker_valid = queue_valid_out; // Conectamos la salida valid de la cola al puerto de entrada del checker



    // =========================================================================
    // Valid 
    // =========================================================================
    parameter MIN_WAIT            = 1;
    parameter MAX_WAIT            = 10;
    parameter DEFAULT_WAIT_CYCLES = 1;
    
    reg [31:0]              valid_wait_cycles = DEFAULT_WAIT_CYCLES;
    reg                     valid_random_cycles = 1; // Flag para habilitar aleatoriedad
    reg [31:0]              valid_cicle_counter;     // Contador de ciclos
    reg                     valid_signal;
    
    assign i_gen_valid = valid_signal;


    
    top_LSFR #(
        .SEED       (SEED),
        .CYCLES     (5),
        .LOCK_THR   (LOCK_THR),
        .UNLOCK_THR (UNLOCK_THR)
    ) u_top_lfsr (
        // Comunes
        .clock            (clock),
        .i_rst            (i_rst),
        // Generador
        .i_gen_enable     (i_gen_enable),      // Conectado al reg i_enable del TB
        .i_soft_reset     (i_soft_reset),
        .i_seed           (i_seed),
        .i_gen_valid      (i_gen_valid),       // Conectado a la señal i_gen_valid del TB (generada aleatoriamente)
        .o_lfsr           (o_lfsr),
        .o_gen_valid      (o_gen_valid),   // Conectado al wire i_gen_valid del TB
        // Checker
        .i_checker_enable (i_checker_enable),
        .i_rst_checker    (i_rst_checker),
        .i_checker_valid  (queue_valid_out), // Conectado a la salida valid de la cola
        .i_checker_data   (queue_data_out),  // Conectado a la salida de datos de la cola
        .o_lock           (o_lock),
        .o_checker        (o_checker)
    );

     // =========================================================================
    // Contadores para el monitoreo de lock/unlock
    // =========================================================================
    int lock_cnt = 0;
    int unlock_cnt = 0;
    reg prev_lock;


    // =========================================================================
    // Contadores para el monitoreo match/mismatch
    // =========================================================================
    integer i = 0; // para iteraciones
    integer valid_cnt = 0; //contador de validos 
    integer match_cnt = 0; //contador de matches correctos

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
            i_seed = $urandom_range(1, 2**NB_LFSR-1); //numero random de 16 bits para el puerto de seed
            #1; 
            $display("Puerto de Seed seteado a: %h", i_seed);
        end
    endtask


    task reset_checker();
        time reset_time;
        begin
            $display("Reset Checker.");
            //----> Activo reset
            i_rst_checker <= 'd1;

            //----> Randomizo duracion del reset
            reset_time = $urandom_range(1,249) * 1ns;
            #reset_time;

            //----> Bajo reset de manera sincronica
            @(posedge clock); // esta linea sirve para esperar a que el clock haga un flanco positivo y luego levantar el reset

            //----> Bajo reset
            i_rst_checker <= 'd0; 
        end
    endtask


    // Monitor Inteligente de Valids
    task monitor_valids(input integer max_valids, input string test_name);
        begin
            valid_cnt = 0;
            match_cnt = 0;
            $display("\n--------- %s ---------", test_name);
            
            while (valid_cnt < max_valids) begin
                // Usamos i_checker_valid porque queremos monitorear lo que sale del Pipe
                if (i_checker_valid) begin 
                    valid_cnt = valid_cnt + 1;
                    
                    if (i_checker_data == o_checker) begin //i_checker_data es lo que le llega al checker y o_checker es lo que el checker predijo para ese ciclo
                        match_cnt = match_cnt + 1;
                        $display("[%0t ns] Valid #%0d | Generador: %h | Recibido: %h | Checker: %h | MATCH    | Matches totales: %0d  |  Lock: %b", 
                                $time, valid_cnt, o_lfsr, i_checker_data, o_checker, match_cnt, o_lock);
                    end else begin
                        $display("[%0t ns] Valid #%0d | Generador: %h | Recibido: %h | Checker: %h | MISMATCH | Matches totales: %0d  |  Lock: %b", 
                                    $time, valid_cnt, o_lfsr, i_checker_data, o_checker, match_cnt, o_lock);
                    end
                end
                @(posedge clock);
            end
        end
    endtask

    // Inyector de Errores (Se usa con fork/join_any)
    task error_injector(input integer num_good, input integer num_bad);
        begin
            // Bucle infinito: intercala N datos sanos con M datos corruptos
            while(1) begin
                repeat(num_good) begin
                    #1;
                    inject_error = 0;
                    @(posedge clock);
                    while(!o_gen_valid) 
                        @(posedge clock); // Esperamos a que salga un dato real
                end
                repeat(num_bad) begin
                    #1;
                    inject_error = 1;
                    @(posedge clock);
                    while(!o_gen_valid) 
                        @(posedge clock);
                end
            end
        end
    endtask

    
    // 2. Proceso de Monitoreo constante de o_lock
    initial begin
        prev_lock = 0;
        forever begin
            @(posedge clock);
            if (o_lock !== prev_lock) begin 
            
                if (o_lock == 1'b1)
                begin
                    $display("[%0t ns] LOCK: El estado de lock cambió a %b", $time, o_lock);
                    lock_cnt++;
                end
                else
                begin
                    $display("[%0t ns] UNLOCK: El estado de lock cambió a %b", $time, o_lock);
                    unlock_cnt++;
                end
                prev_lock = o_lock;
            end
        end
    end


    
    `include "./valid_generator.sv"
    `include "./queue.sv"





    `define TEST6
        
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

    `ifdef TEST4
        `include "./TEST4.sv"
    `endif

    `ifdef TEST5
        `include "./TEST5.sv"
    `endif

    `ifdef TEST6
        `include "./TEST6.sv"
    `endif




endmodule
