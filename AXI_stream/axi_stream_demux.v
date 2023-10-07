module stream_demux #(
        parameter DATA_WD = 4
    )(
        input                       sel,
        input                       clk,
        input                       rst_n,

        input                       a_valid,
        input  [DATA_WD - 1 : 0]    a_data,
        output                      a_ready,

        output                      b_valid,
        output [DATA_WD - 1 : 0]    b_data,
        input                       b_ready,

        output                      c_valid,
        output [DATA_WD - 1 : 0]    c_data,
        input                       c_ready
    );

    wire    c_fire  = c_ready && c_valid;
    wire    a_fire  = a_ready && a_valid;
    wire    b_fire  = b_ready && b_valid;

    assign             b_data = a_data;
    assign             c_data = a_data;

    assign            a_ready = sel ? b_ready : c_ready;
    assign {b_valid, c_valid} = sel ? {a_valid, 1'b0} : {1'b0, a_valid};
endmodule
