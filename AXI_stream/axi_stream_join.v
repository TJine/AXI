module stream_join #(
        parameter DATA_WD = 4,
        parameter HA_LAST = 0
    )(
        input                       clk,
        input                       rst_n,

        input                       a_valid,
        input  [DATA_WD - 1 : 0]    a_data,
        input                       a_last,
        output                      a_ready,

        input                       b_valid,
        input  [DATA_WD - 1 : 0]    b_data,
        output                      b_ready,

        output                      c_valid,
        output [2*DATA_WD - 1 : 0]  c_data,
        output                      c_last,
        input                       c_ready
    );

    wire    c_fire  = c_ready && c_valid;

    assign  c_valid = a_valid && b_valid;
    assign  c_last  = a_last;
    assign  c_data  = {b_data, a_data};

    generate if (HA_LAST) begin
                assign a_ready = c_fire;
                assign b_ready = c_fire && a_last;
            end
            else begin
                assign a_ready = c_fire;
                assign b_ready = c_fire;
            end
    endgenerate
endmodule
