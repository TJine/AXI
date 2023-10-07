module tb_axi_master();
    localparam ADDR_WD   = 32;
    localparam DATA_WD   = 32;
    localparam STRB_WD   = DATA_WD >> 3;
    localparam [1 : 0]  INCR = 2'b01;
    localparam DW_BYTE   = DATA_WD >> 3;
    localparam CNTR_WD   = ADDR_WD - $clog2(DW_BYTE);

    localparam DEPTH   = 8191;

    reg [7 : 0] mem [0 : DEPTH];

    reg                      clk;
    reg                      reset;
    wire [DATA_WD - 1 : 0]   r_arlen;                    

    reg                      w_cmd_valid;
    reg  [ADDR_WD - 1 : 0]   w_cmd_len;
    reg  [ADDR_WD - 1 : 0]   w_cmd_addr;
    wire [1 : 0]             w_cmd_burst;
    wire [2 : 0]             w_cmd_size;
    wire                     w_cmd_ready;

    reg                      r_cmd_valid;
    reg  [ADDR_WD - 1 : 0]   r_cmd_len;
    reg  [ADDR_WD - 1 : 0]   r_cmd_addr;
    wire [1 : 0]             r_cmd_burst;
    wire [2 : 0]             r_cmd_size;
    wire                     r_cmd_ready;

    wire                     M_AXI_AWVALID;
    wire [1 : 0]             M_AXI_AWBURST;
    wire [2 : 0]             M_AXI_AWSIZE;
    wire [7 : 0]             M_AXI_AWLEN;
    wire [ADDR_WD - 1 : 0]   M_AXI_AWADDR;
    reg                      M_AXI_AWREADY;

    wire                     M_AXI_WVALID;
    wire [DATA_WD - 1 : 0]   M_AXI_WDATA;
    wire [STRB_WD - 1 : 0]   M_AXI_WSTRB;
    wire                     M_AXI_WLAST;
    reg                      M_AXI_WREADY;

    reg                      M_AXI_BVALID;
    reg [1 : 0]              M_AXI_BRESP;
    wire                     M_AXI_BREADY;

    wire                     M_AXI_ARVALID;
    wire [1 : 0]             M_AXI_ARBURST;
    wire [2 : 0]             M_AXI_ARSIZE;
    wire [7 : 0]             M_AXI_ARLEN;
    wire [ADDR_WD - 1 : 0]   M_AXI_ARADDR;
    reg                      M_AXI_ARREADY;

    reg                     M_AXI_RVALID;
    reg [DATA_WD - 1 : 0]   M_AXI_RDATA;
    reg [1 : 0]             M_AXI_RRESP;
    reg                     M_AXI_RLAST;
    wire                     M_AXI_RREADY;

    axi_master #(
        .ADDR_WD(ADDR_WD),
        .DATA_WD(DATA_WD),
        .STRB_WD(STRB_WD))
    axi_master (
        .clk            (clk),
        .reset          (reset),
        
        .w_cmd_valid    (w_cmd_valid),
        .w_cmd_ready    (w_cmd_ready),
        .w_cmd_addr     (w_cmd_addr),
        .w_cmd_burst    (w_cmd_burst),
        .w_cmd_len      (w_cmd_len),
        .w_cmd_size     (w_cmd_size),

        .r_cmd_valid    (r_cmd_valid),
        .r_cmd_ready    (r_cmd_ready),
        .r_cmd_addr     (r_cmd_addr),
        .r_cmd_burst    (r_cmd_burst),
        .r_cmd_len      (r_cmd_len),
        .r_cmd_size     (r_cmd_size),
        .r_arlen        (r_arlen)
    );

    initial begin
        clk = 1;
        forever #5 clk = ~clk;
    end

    initial begin
        reset = 0;
        #50 reset = 1;
        #100000 $finish;
    end

    // cmd_valid

    // cmd_len
    always @(posedge clk) begin
        if (!reset) begin
            w_cmd_len <= 'h100;
        end
    end

    always @(posedge clk) begin
        if (!reset) begin
            r_cmd_len <= 'h800;
        end
    end


    always @(posedge clk) begin
        if (~reset) begin
            w_cmd_valid <= 0;
            r_cmd_valid <= 0;
        end
        else begin
            if (!w_cmd_valid || w_cmd_ready) begin
                w_cmd_valid <= 1;
            end
            if (!r_cmd_valid || r_cmd_ready) begin
                r_cmd_valid <= 1;
            end
        end
    end
    
    // w_cmd_burst
    assign w_cmd_burst = INCR;
    assign r_cmd_burst = INCR;

    // w_cmd_addr
    // assign w_cmd_addr = 'h8;
    // assign r_cmd_addr = 'h8;
    reg [ADDR_WD - 1 : 0] w_addr;
    reg [ADDR_WD - 1 : 0] r_addr;
    always @(*) begin
        if (!reset) begin
            w_addr = 'h0;
        end
        else begin
            if (w_cmd_valid && w_cmd_ready) begin
                w_addr = w_addr + w_cmd_len;
            end
        end   
    end

    always @(posedge clk) begin
        if (!reset) begin
            w_cmd_addr <= 'h8;
        end
        else begin
            w_cmd_addr <= w_addr;
        end
    end

    always @(*) begin
        if (!reset) begin
            r_addr = 'h0;
        end
        else begin
            if (r_cmd_valid && r_cmd_ready) begin
                r_addr = r_addr + r_cmd_len;
            end
        end   
    end

    always @(posedge clk) begin
        if (!reset) begin
            r_cmd_addr <= 'h8;
        end
        else begin
            r_cmd_addr <= r_addr;
        end
    end

    // w_cmd_size
    assign w_cmd_size  = $clog2(STRB_WD);
    assign r_cmd_size  = $clog2(STRB_WD);
endmodule
