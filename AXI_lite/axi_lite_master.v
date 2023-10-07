module AXI_lite_master #(
        parameter DATA_WD = 8,
        parameter ADDR_WD = 8,
        parameter DATA_ADDR_BYTE_WD = (DATA_WD + ADDR_WD) >> 3
    ) (
        input                               clk,
        input                               rst_n,

        input                               tvalid,
        input   [ADDR_WD + DATA_WD - 1 : 0] tdata,
        input   [DATA_ADDR_BYTE_WD - 1 : 0] tkeep,
        output                              tready,

        output                              awvalid,
        output  [ADDR_WD - 1 : 0]           awaddr,
        input                               awready,

        output                              wvalid,
        output  [DATA_WD - 1 : 0]           wdata,
        input                               wready,

        input                               bvalid,
        input   [1 : 0]                     brsp,
        output                              bready,

        output                              arvalid,
        output  [ADDR_WD - 1 : 0]           araddr,
        input                               arready,

        input                               rvalid,
        input   [DATA_WD - 1 : 0]           rdata,
        input   [1 : 0]                     rrsp,
        output                              rready  
    );

    // stream demux
    wire write_cmd = &tkeep;

    wire tvalid4w = tvalid && write_cmd;
    wire tvalid4r = tvalid && ~write_cmd;

    wire [DATA_WD - 1 : 0] tdata4w  = tdata[DATA_WD - 1 : 0];
    wire [ADDR_WD - 1 : 0] taddr4w  = tdata[DATA_WD + ADDR_WD - 1 -: ADDR_WD];
    wire [ADDR_WD - 1 : 0] taddr4r  = tdata[DATA_WD + ADDR_WD - 1 -: ADDR_WD];

    wire tready4w;
    wire tready4r;

    assign tready   = (tready4w && write_cmd) || (tready4r && ~write_cmd);

    read_master #(.DATA_WD(DATA_WD), .ADDR_WD(ADDR_WD)) read_master(
        .clk        (clk),
        .rst_n      (rst_n),

        .tvalid     (tvalid4r),
        .taddr      (taddr4r),
        .tready     (tready4r),

        .arvalid    (arvalid),
        .arready    (arready),
        .araddr     (araddr),

        .rvalid     (rvalid),
        .rready     (rready),
        .rdata      (rdata),
        .rrsp       (rrsp)
    );

    write_master #(.DATA_WD(DATA_WD), .ADDR_WD(ADDR_WD)) write_master(
        .clk        (clk),
        .rst_n      (rst_n),

        .tvalid     (tvalid4w),
        .taddr      (taddr4w),
        .tdata      (tdata4w),
        .tready     (tready4w),

        .awvalid    (awvalid),
        .awaddr     (awaddr),
        .awready    (awready),

        .wvalid     (wvalid),
        .wdata      (wdata),
        .wready     (wready),

        .bvalid     (bvalid),
        .bready     (bready),
        .brsp       (brsp)
    );
endmodule

module read_master #(
        parameter DATA_WD = 8,
        parameter ADDR_WD = 8
    ) (
        input                               clk,
        input                               rst_n,

        input                               tvalid,
        input   [ADDR_WD - 1 : 0]           taddr,
        output                              tready,

        output                              arvalid,
        output  [ADDR_WD - 1 : 0]           araddr,
        input                               arready,

        input                               rvalid,
        input   [DATA_WD - 1 : 0]           rdata,
        input   [1 : 0]                     rrsp,
        output                              rready
    );

    reg  [ADDR_WD - 1 : 0]  araddr_r;
    reg                     arvalid_r;
    reg                     rready_r;

    wire t_fire  = tvalid && tready;
    wire ar_fire = arvalid && arready;
    wire r_fire  = rvalid  && rready;

    assign arvalid = arvalid_r;
    assign araddr  = araddr_r;
    assign rready  = rready_r;

    wire hs_rrsp_pending = rvalid && !rready;

    assign tready = !hs_rrsp_pending;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            arvalid_r  <= 'b0;
            araddr_r <= 'b0;
            rready_r <= 'b0;
        end
        else begin
            if (ar_fire) begin
                arvalid_r <= 1'b0;
            end
            if (r_fire) begin
                rready_r <= 1'b0;
            end
            if (ar_fire) begin
                rready_r <= 1'b1;
            end
            if (t_fire) begin
                arvalid_r <= 1'b1;
                araddr_r  <= taddr;
            end
        end
    end
endmodule

module write_master #(
        parameter DATA_WD = 8,
        parameter ADDR_WD = 8
    ) (
        input                               clk,
        input                               rst_n,

        input                               tvalid,
        input   [DATA_WD - 1 : 0]           tdata,
        input   [ADDR_WD - 1 : 0]           taddr,
        output                              tready,

        output                              awvalid,
        output  [ADDR_WD - 1 : 0]           awaddr,
        input                               awready,

        output                              wvalid,
        output  [DATA_WD - 1 : 0]           wdata,
        input                               wready,

        input                               bvalid,
        input   [1 : 0]                     brsp,
        output                              bready
    );

    reg [ADDR_WD - 1 : 0]   awaddr_r;
    reg                     awvalid_r;
    reg                     wvalid_r;
    reg [DATA_WD - 1 : 0]   wdata_r;
    reg                     bready_r;

    reg                     aw_fired;
    reg                     w_fired;

    wire t_fire  = tvalid && tready;
    wire aw_fire = awvalid && awready;
    wire w_fire  = wvalid && wready;
    wire b_fire  = bvalid && bready;

    wire hs_brsp_pending = bvalid && !bready;

    assign tready = !hs_brsp_pending;

    assign awvalid = awvalid_r;
    assign awaddr  = awaddr_r;
    assign wvalid  = wvalid_r;
    assign wdata   = wdata_r;
    assign bready  = bready_r; 

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            aw_fired  <= 'b0;
            w_fired   <= 'b0;

            awvalid_r <= 'b0;
            awaddr_r  <= 'b0;
            wvalid_r  <= 'b0;
            wdata_r   <= 'b0;
            bready_r  <= 'b0;
        end
        else begin
            if (aw_fire) begin
                aw_fired <= 1'b1;
                awvalid_r<= 1'b0;
            end
            if (w_fire) begin
                w_fired  <= 1'b1;
                wvalid_r <= 1'b0;
            end
            if (t_fire) begin
                awvalid_r <= 1'b1;
                wvalid_r  <= 1'b1;
                awaddr_r  <= taddr;
                wdata_r   <= tdata;
            end
            if (aw_fire && w_fire) begin
                bready_r <= 1'b1;
            end
            else if (aw_fired && w_fire) begin
                bready_r <= 1'b1;
            end
            else if (aw_fire && w_fired) begin
                bready_r <= 1'b1;
            end
        end
    end
endmodule
