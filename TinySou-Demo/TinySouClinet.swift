//
//  TinySouClinet.swift
//  TinySou-Demo
//
//  Created by Free Storm on 14-10-27.
//  Copyright (c) 2014年 tinysou. All rights reserved.
//

import Foundation
import SwiftyJSON

public class TinySouClient{
    //设置engine_key
    private var engine_key: String!
    //http请求方法
    private var method = "POST"
    //搜索url
    private var search_url = "http://api.tinysou.com/v1/public/search"
    //自动补全url
    private var ac_url = "http://api.tinysou.com/v1/public/autocomplete"
    //显示的页数
    private var page = 0
    //状态判断
    private var is_error = false
    //每页显示的页数
    private var per_page = 10
    //json结果返回
    private var json: JSON?
    //error信息
    private var error_message: String?
    
    //初始化函数
    public init(engine_key: String){
        self.engine_key = engine_key
    }
    
    //设置搜索页数
    public func setPage(page: Int){
        self.page = page
    }
    
    //获取搜索页数
    public func getPage() ->Int{
        return self.page
    }
    
    //设置每页显示的页数
    public func setPerPage(per_page: Int){
        self.per_page = per_page
    }
    
    //获取每页显示的页数
    public func getPerPage() ->Int{
        return self.per_page
    }
    
    //获取搜索url
    public func getSearchUrl() ->String{
        return self.search_url
    }
    
    //获取自动补全url
    public func getAcUrl() ->String{
        return self.ac_url
    }
    
    //判断是否出错
    public func isError() ->Bool{
        return self.is_error
    }
    
    //获取搜索结果
    public func getJson() ->JSON{
        return self.json!
    }
    
    //新建搜索request
    public func buildRequest(search_content: String) -> NSURLRequest {
        var url = NSURL(string: search_url)
        //新建request
        var request = NSMutableURLRequest(URL: url!)
        //设置请求方法
        request.HTTPMethod = self.method
        //定义json数据
        var json: JSON?
        //定义报错
        var err: NSError?
        //设置header
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        //设置body
        var params = ["q": search_content, "c": "page", "page": String(self.page), "engine_key":self.engine_key, "per_page": String(self.per_page)] as Dictionary<String, String>
        request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options: nil, error: &err)
        return request
    }
    
    //新建自动补全request
    public func buildAcRequest(search_content: String) -> NSURLRequest {
        var url = NSURL(string: ac_url)
        //新建request
        var request = NSMutableURLRequest(URL: url!)
        //设置请求方法
        request.HTTPMethod = self.method
        //定义报错
        var err: NSError?
        //定义json数据
        var json: JSON?
        //设置header
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        var fetch_field: Array = ["title", "sections", "url", "updated_at"]
        //设置body
        var params = ["q": search_content, "c": "page",  "engine_key": self.engine_key, "per_page": String(self.per_page), "fetch_fields": fetch_field] as Dictionary<String, AnyObject>
        request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options: nil, error: &err)
        return request
    }
    
    //响应数据处理
    public func handleResult(data: NSData) ->JSON {
        var strData = NSString(data: data, encoding: NSUTF8StringEncoding)
        var err: NSError?
        var jsonObj = NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves, error: &err) as? NSDictionary
        var json: JSON!
        json = JSON(jsonObj!)
        if( json == nil) {
            self.is_error = true
            self.error_message = "json数据解析失败"
            println(self.error_message)
        } else {
            self.is_error = false
        }
        return json
    }
    
}