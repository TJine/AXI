module axi_stream_fork #(
        parameter DATA_WD = 4,
        parameter COMBO = 0
    )(
        input                       clk,
        input                       rst_n,

        input                       a_valid,
        input  [2*DATA_WD - 1 : 0]  a_data,
        output                      a_ready,

        output                      b_valid,
        output [DATA_WD - 1 : 0]    b_data,
        input                       b_ready,

        output                      c_valid,
        output [DATA_WD - 1 : 0]    c_data,
        input                       c_ready
    );

    reg     b_fire_r;
    reg     c_fire_r;

    wire    c_fire  = c_ready && c_valid;
    wire    a_fire  = a_ready && a_valid;
    wire    b_fire  = b_ready && b_valid;

    assign  b_data = a_data[2*DATA_WD - 1 : DATA_WD];
    assign  c_data = a_data[DATA_WD - 1 : 0];

    generate if (COMBO) begin // valid 依赖 ready, 绝对不允许
                assign b_valid = a_fire;
                assign c_valid = a_fire;
                assign a_ready = b_ready && c_ready;
            end
            else begin
                assign b_valid = a_valid && !b_fire_r;
                assign c_valid = a_valid && !c_fire_r;
                assign a_ready = (b_ready && c_ready) || (b_fire_r && c_fire_r);

                always @(posedge clk or negedge rst_n) begin
                    if (~rst_n) begin
                        b_fire_r <= 'b0;
                        c_fire_r <= 'b0;
                    end
                    else begin
                        if (b_fire) begin
                            b_fire_r <= b_fire;
                        end
                        if (c_fire) begin
                            c_fire_r <= c_fire;
                        end
                        if (a_fire) begin
                            b_fire_r <= 'b0;
                            c_fire_r <= 'b0;
                        end        
                    end
                end
            end
    endgenerate
endmodule
