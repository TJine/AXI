module axi_stream_mux #(
        parameter DATA_WD = 4
    )(
        input                       sel,    
        input                       clk,
        input                       rst_n,

        input                       a_valid,
        input  [DATA_WD - 1 : 0]    a_data,
        output                      a_ready,

        input                       b_valid,
        input  [DATA_WD - 1 : 0]    b_data,
        output                      b_ready,

        output                      c_valid,
        output [DATA_WD - 1 : 0]    c_data,
        input                       c_ready
    );
    
    wire    c_fire  = c_ready && c_valid;
    wire    a_fire  = a_ready && a_valid;
    wire    b_fire  = b_ready && b_valid;

    assign {a_ready, b_ready} = sel ? {c_ready, 1'b0} : {1'b0, c_ready};

    assign            c_valid = sel ? a_valid : b_valid;

    assign             c_data = sel ? a_data  : b_data;
endmodule
