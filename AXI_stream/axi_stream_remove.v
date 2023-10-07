// data_in = 32'hABCDABCD
// keep_in = 4'b1111

// aligned read/write:
// address: 0 4 8 C
// unaligned read/write:
// address: 1 2 3 5 6 7 9 A B D E 

// unaligned address: 0xA
// unaligned keep = 4'b1111
// nearest aligned address: 0x8
// aligned keep = 4'b0011

// data_length: 0x7
// unaligned from 0xA
// first beat:
// keep: 4'b1111 0xA - 0xD
// last beat:
// keep: 4'b1110 0xE - 0x11

// aligned from 0x8
// first beat:
// keep: 4'b0011 0x8 - 0xB
// second beat:
// keep: 4'b1111 0xC - 0xF
// last beat:
// keep: 4'b1000 0x10 - 0x13

// data_length: 0xA
// unaligned from 0xA
// first beat:
// keep: 4'b1111 0xA - 0xD
// second beat:
// keep: 4'b1111 0xE - 0x11
// last beat:
// keep: 4'b1100 0x12 - 0x15

// aligned from 0x8
// first beat:
// keep: 4'b0011 0x8 - 0xB
// second beat:
// keep: 4'b1111 0xC - 0xF
// last beat:
// keep: 4'b1111 0x10 - 0x13

module stream_remove#(  
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

        input                           valid_remove,
        input   [BYTE_CNT_WD - 1 : 0]   byte_remove_cnt,
        output                          ready_remove
    );

    localparam DATA_BIT_CNT_WD = $clog2(DATA_WD);

    reg  [DATA_WD - 1 : 0]      data_in_r;
    reg  [DATA_BYTE_WD - 1 : 0] keep_in_r;

    reg                         valid_in_r;
    reg                         first_beat_r;
    reg                         extra_beat_r;

    wire fire_in     = valid_in     && ready_in;
    wire fire_out    = valid_out    && ready_out;
    wire fire_remove = valid_remove && ready_remove;

    // 当输入的最后一拍是输出的倒数第二拍时，需要额外拍。
    // keep_in = 1111_1100
    // byte_remove_cnt = 2
    // keep_out = 1111
    // has_extra_beat = 0
    // 也就是说当keep_in中1的个数等于要移除字节的个数时，不需要额外拍。
    wire [DATA_BYTE_WD - 1 : 0]     next_beat_byte = keep_in << byte_remove_cnt;
    wire                            has_extra_beat = |next_beat_byte && !extra_beat_r;

    wire [DATA_BYTE_WD - 1 : 0]     keep_nothing   = {DATA_BYTE_WD{1'b0}};
    wire [2*DATA_WD - 1 : 0]        double_data    = {data_in_r, data_in};
    wire [2*DATA_BYTE_WD - 1 : 0]   double_keep    = extra_beat_r ? {keep_in_r , keep_nothing} : {keep_in_r, keep_in};

    // wire [BYTE_CNT_WD  : 0]               data_byte_cnt = DATA_BYTE_WD; 
    wire [BYTE_CNT_WD  : 0]         right_shift_byte_cnt = DATA_BYTE_WD - byte_remove_cnt;
    wire [DATA_BIT_CNT_WD  : 0]     right_shift_bit_cnt = right_shift_byte_cnt << 3;

    assign data_out = double_data >> right_shift_bit_cnt;
    assign keep_out = double_keep >> right_shift_byte_cnt;

    assign ready_remove = fire_out && last_out;
    assign ready_in     = !valid_in_r || (ready_out && valid_remove);
    assign valid_out    = extra_beat_r ? (valid_in_r && valid_remove) : (valid_in_r && valid_in && valid_remove);
    assign last_out     = (!has_extra_beat && last_in) || extra_beat_r;
 
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
            first_beat_r <= 1'b1;
        end
        else if (fire_in && last_in) begin
            first_beat_r <= 1'b1;
        end
        else if (fire_in) begin
            first_beat_r <= 1'b0;
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
                valid_in_r <= 1;
                // valid_in_r <= has_extra_beat;
            end
        end
    end
endmodule
