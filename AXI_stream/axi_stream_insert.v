// keep_in      = 4'b1111
// last_keep_in = 4'b1111, 4'b1110, 4'b1100, 4'b1000 no 4'b0000
// keep_insert  = 4'b0111, 4'b0011, 4'b0001, 4'b0000 no 4'b1111
// keep_out     = 4'b1111

// first input beat:
// keep_in      = 4'b1111
// keep_insert  = 4'b0011
// keep_out     = 4'b1111

// last input beat:
// keep_in      = 4'b1000
// keep_insert  = 4'b0011
// last output beat, no extra:
// keep_out = 4'b1110

// last input beat:
// keep_in      = 4'b1110
// keep_insert  = 4'b0011
// last output beat, has extra
// keep_out = 4'b1000

module axi_stream_insert#(
        parameter DATA_WD = 32,
        parameter DATA_BYTE_WD = DATA_WD >> 3,
        parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD)
    ) (
        input                           clk,
        input                           rst_n,

        input                           valid_in,
        input   [DATA_WD - 1 : 0]       data_in,
        input   [DATA_BYTE_WD - 1 : 0]  keep_in,
        input                           last_in,
        output                          ready_in,

        output                          valid_out,
        output  [DATA_WD - 1 : 0]       data_out,
        output  [DATA_BYTE_WD - 1 : 0]  keep_out,
        output                          last_out,
        input                           ready_out,

        input                           valid_insert,
        input   [DATA_WD - 1 : 0]       data_insert,
        input   [DATA_BYTE_WD - 1 : 0]  keep_insert,
        input   [BYTE_CNT_WD - 1 : 0]   byte_insert_cnt,
        output                          ready_insert
    );

    localparam DATA_BIT_CNT_WD = $clog2(DATA_WD);

    reg  [DATA_WD - 1 : 0]      data_in_r;
    reg  [DATA_BYTE_WD - 1 : 0] keep_in_r;
    reg                         valid_in_r;

    reg                         first_beat_r;
    reg                         extra_beat_r;

    wire fire_in     = valid_in     && ready_in;
    wire fire_out    = valid_out    && ready_out;
    wire fire_insert = valid_insert && ready_insert;

    wire [DATA_BYTE_WD - 1 : 0]     keep_nothing = {DATA_BYTE_WD{1'b0}};
    wire [2*DATA_WD - 1 : 0]        double_data  = first_beat_r ? {data_insert, data_in} : {data_in_r, data_in};
    wire [2*DATA_BYTE_WD - 1 : 0]   double_keep  = first_beat_r ? {keep_insert, keep_in} : 
                                                   (extra_beat_r ? {keep_in_r, keep_nothing} :
                                                                  {keep_in_r, keep_in});
 
    wire [BYTE_CNT_WD  : 0]         right_shift_byte_cnt = byte_insert_cnt;
    wire [DATA_BIT_CNT_WD  : 0]     right_shift_bit_cnt = right_shift_byte_cnt << 3;

    // wire [BYTE_CNT_WD : 0]                data_byte_cnt = DATA_BYTE_WD;
    wire [BYTE_CNT_WD : 0]          left_shift_byte_cnt = DATA_BYTE_WD - byte_insert_cnt;
    wire [DATA_BYTE_WD - 1 : 0]     next_beat_byte = keep_in << left_shift_byte_cnt;
    wire                            has_extra_beat = |next_beat_byte && !extra_beat_r;
    
    assign data_out     = double_data >> right_shift_bit_cnt;
    assign keep_out     = double_keep >> right_shift_byte_cnt;

    assign ready_in     = !valid_in_r || (ready_out && valid_insert && !extra_beat_r); // 额外拍valid_in_r有效，没有空间接收新数据
    assign last_out     = (!has_extra_beat && last_in) || extra_beat_r;
    assign ready_insert = fire_out && last_out;
    assign valid_out    = first_beat_r ? valid_in :
                         (extra_beat_r ? valid_in_r :
                                        (valid_in_r && valid_in))
                         && valid_insert;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            first_beat_r <= 'b1;
        end
        else if (fire_out && last_out) begin
            first_beat_r <= 1'b1;
        end
        else if (fire_out) begin
            first_beat_r <= 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            extra_beat_r <= 1'b0;
        end
        else begin
            if (fire_in && last_in) begin
                extra_beat_r <= has_extra_beat;
            end
            else if (fire_out) begin
                extra_beat_r <= 1'b0;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            data_in_r  <= 'b0;
            keep_in_r  <= 'b0;
            valid_in_r <= 'b0;
        end
        else begin 
            if (fire_out) begin
                valid_in_r <= 1'b0;
            end
            if (fire_in) begin
                data_in_r  <= data_in;
                keep_in_r  <= keep_in;
                valid_in_r <= 1'b1;
            end
        end
    end
endmodule
