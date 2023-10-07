module tb_stream_insert ();
    localparam HAL_CYCLE    = 5;
    localparam DATA_WD      = 32;
    localparam DATA_BYTE_WD = DATA_WD >> 3;
    localparam BYTE_CNT_WD  = $clog2(DATA_BYTE_WD);

    reg clk;
    reg rst_n;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end 
    
    initial begin
        rst_n = 0;
        #100 rst_n = 1;
        #5000 $finish;
    end

    reg  [DATA_WD - 1 : 0]      data_in;
    reg  [BYTE_CNT_WD - 1 : 0]  last_beat_invalid_byte_cnt;
    reg  [1 : 0]                data_input_beat_cnt; // 总拍数
    reg                         valid_in;

    wire                        last_in = &data_input_beat_cnt; // data_input_beat_cnt = 2'b11 时说明是输入最后一拍
    wire [DATA_BYTE_WD - 1 : 0] keep_in = last_in ? ~((1 << last_beat_invalid_byte_cnt) - 1) : (1 << DATA_BYTE_WD) - 1;
    wire                        ready_in;
    
    reg  [BYTE_CNT_WD - 1 : 0]  byte_insert_cnt;
    reg  [DATA_WD - 1 : 0]      data_insert;
    wire [DATA_BYTE_WD - 1 : 0] keep_insert = (1 << DATA_BYTE_WD) - 1;
    reg                         valid_insert;
    wire                        ready_insert;

    wire [DATA_WD - 1 : 0]      data_out;
    wire [DATA_BYTE_WD - 1 : 0] keep_out;
    wire                        last_out;
    wire                        valid_out;
    reg                         ready_out;

    wire fire_in     = valid_in     && ready_in;
    wire fire_out    = valid_out    && ready_out;
    wire fire_insert = valid_insert && ready_insert;

    stream_insert #(.DATA_WD(DATA_WD),.DATA_BYTE_WD(DATA_BYTE_WD),.BYTE_CNT_WD(BYTE_CNT_WD))
    stream_insert(
        .clk        (clk),
        .rst_n      (rst_n),

        .valid_in   (valid_in),
        .data_in    (data_in),
        .keep_in    (keep_in),
        .last_in    (last_in),
        .ready_in   (ready_in),
        
        .valid_out  (valid_out),
        .data_out   (data_out),
        .keep_out   (keep_out),
        .last_out   (last_out),
        .ready_out  (ready_out),

        .valid_insert   (valid_insert),
        .data_insert    (data_insert),
        .keep_insert    (keep_insert),
        .byte_insert_cnt(byte_insert_cnt),
        .ready_insert   (ready_insert)
    );

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            data_in <=$random;
            data_insert <= 'd0;
        end
        else begin
            if (fire_in) begin
                data_in <= $random;
            end
            if (fire_insert) begin
                data_insert <= 'd0;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            byte_insert_cnt     <= 'b0;
            data_input_beat_cnt <= 'b0;
            last_beat_invalid_byte_cnt  <= 'b0;
        end
        else begin
            byte_insert_cnt     <= byte_insert_cnt + fire_insert;
            data_input_beat_cnt <= data_input_beat_cnt + fire_in;

            if (fire_out && last_out && (&byte_insert_cnt)) begin
                last_beat_invalid_byte_cnt <= last_beat_invalid_byte_cnt + 1'b1;
                if (last_beat_invalid_byte_cnt == DATA_BYTE_WD - 1) begin
                    last_beat_invalid_byte_cnt <= 1'b0;
                end
            end
        end
    end

    localparam RANDOM_FIRE = 1'b0;

    generate if (RANDOM_FIRE) begin
                always @(posedge clk or negedge rst_n) begin
                    if (~rst_n) begin
                        valid_insert <= 1'b0;
                        valid_in     <= 1'b0;
                        ready_out    <= 1'b1;
                    end
                    else if (!valid_insert || ready_insert) begin
                        valid_insert <= $random;
                    end
                    else if (!valid_in || ready_in) begin
                        valid_in <= $random;
                    end

                    ready_out <= $random;
                end
            end
            else begin
                always @(posedge clk or negedge rst_n) begin
                    if (~rst_n) begin
                        valid_insert <= 1'b0;
                        valid_in     <= 1'b0;
                        ready_out    <= 1'b1;
                    end
                    else begin
                        valid_insert <= 1'b1;
                        valid_in <= 1'b1;
                        ready_out <= 1'b1;
                    end
                end
            end
    endgenerate
endmodule
