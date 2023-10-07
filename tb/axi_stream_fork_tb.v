module axi_stream_fork_tb ();

    localparam DATA_WD = 4;
    localparam COMBO = 0;

    reg                         clk;
    reg                         rst_n;

    reg                         a_valid;
    wire [2*DATA_WD - 1 : 0]    a_data;
    wire                        a_ready;

    wire                        b_valid;
    wire [DATA_WD - 1 : 0]      b_data;
    reg                         b_ready;

    wire                        c_valid;
    wire [DATA_WD - 1 : 0]      c_data;
    reg                         c_ready;

    reg  [2*DATA_WD - 1 : 0]      a_in;

    assign a_data = a_in;

    assign a_fire = a_valid && a_ready;
    assign b_fire = b_valid && b_ready;


    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst_n = 0;
        #100 rst_n = 1;
        #5000 $finish;
    end

    stream_fork #(
        .DATA_WD(DATA_WD),
        .COMBO(COMBO)
    ) stream_fork(
        .clk    (clk),
        .rst_n  (rst_n),
        .a_valid(a_valid),
        .a_data (a_data),
        .a_ready(a_ready),
        .b_valid(b_valid),
        .b_data (b_data),
        .b_ready(b_ready),
        .c_valid(c_valid),
        .c_data (c_data),
        .c_ready(c_ready)
    );

    localparam RANDOM_FIRE = 1'b1;

    generate if (RANDOM_FIRE) begin // random fire

                always @(posedge clk or negedge rst_n) begin
                    if (!rst_n) begin
                        a_valid <= 1'b0;
                        a_in <= 'b0;
                    end
                    else begin
                        if (!a_valid) begin
                            a_valid <= $random;
                        end
                        else if (a_fire) begin
                            a_valid <= $random;
                            a_in <= a_in + 1'b1;
                        end
                    end
                end
                
                always @(posedge clk or negedge rst_n) begin
                    if (!rst_n) begin
                        b_ready <= 1'b1;
                        c_ready <= 1'b1;
                    end
                    else begin
                        b_ready <= $random;
                        c_ready <= $random;
                    end
                end
            end
            else begin
                always @(posedge clk or negedge rst_n) begin
                    if (!rst_n) begin
                        a_valid <= 1'b0;
                        a_in <= 'b0;
                    end
                    else begin
                        a_valid <= 1'b1;
                        if (a_fire) begin
                            a_in <= a_in + 1'b1;
                        end
                    end
                end

                always @(posedge clk or negedge rst_n) begin
                    if (!rst_n) begin
                        b_ready <= 1'b1;
                        c_ready <= 1'b1;
                    end
                    else begin
                        b_ready <= 1;
                        c_ready <= 1;
                    end
                end
            end
    endgenerate
endmodule
