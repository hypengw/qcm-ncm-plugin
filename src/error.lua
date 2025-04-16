   
--[[
            if (var11 == 506) {
               return -8;
            }

            if (var11 == 511) {
               return -7;
            }

            if (var11 == 502 || var11 == 404) {
               return -2;
            }

            if (var11 == 515) {
               return -9;
            }

            if (var11 == 505) {
               return -4;
            }

            if (var11 == 400) {
               return -5;
            }

            if (var11 == 420) {
               return -6;
            }

            if (var11 == 401) {
               return -6;
            }

            if (var11 == 512) {
               return -10;
            }

java:
      c var5 = new c("SUCCEEDED", 0, 9000, "处理成功");
      c = var5;
      c var0 = new c("FAILED", 1, 4000, "系统繁忙，请稍后再试");
      d = var0;
      c var7 = new c("CANCELED", 2, 6001, "用户取消");
      e = var7;
      c var3 = new c("NETWORK_ERROR", 3, 6002, "网络连接异常");
      f = var3;
      c var6 = new c("ACTIVITY_NOT_START_EXIT", 4, 6007, "支付未完成");
      g = var6;
      c var2 = new c("PARAMS_ERROR", 5, 4001, "参数错误");
      h = var2;
      c var4 = new c("DOUBLE_REQUEST", 6, 5000, "重复请求");
      i = var4;
      c var1 = new c("PAY_WAITTING", 7, 8000, "支付结果确认中");

   private static String[] resolveRepState(int var0, String var1) {
      String var2;
      String var3;
      switch (var0) {
         case 0:
            var3 = "0000";
            var2 = "成功";
            break;
         case 1:
            var3 = "1000";
            var2 = "未知的命令";
            break;
         case 2:
            var3 = "1001";
            var2 = "验签失败";
            break;
         case 3:
            var3 = "1002";
            var2 = "参数错误";
            break;
         case 4:
            var3 = "1003";
            var2 = "请求超时";
            break;
         case 5:
            var3 = "1004";
            var2 = "版本过低";
            break;
         case 6:
            var3 = "1005";
            var2 = "客户端不支持，请升级客户端";
            break;
         case 7:
            var3 = "2001";
            var2 = "请求失败";
            break;
         case 8:
            var3 = "2002";
            var2 = "用户取消";
            break;
         default:
            var3 = null;
            var2 = null;
      }
]]