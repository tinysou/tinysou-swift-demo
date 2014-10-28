//
//  ViewController.swift
//  TinySou-Demo
//
//  Created by Free Storm on 14-10-27.
//  Copyright (c) 2014年 tinysou. All rights reserved.
//

import UIKit
import SwiftyJSON
import TinySouSwift

class ViewController: UIViewController ,UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate {

    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchResultCell: UITableView!
    var refreshControl: UIRefreshControl!
    
    let CellIdentifier: String = "searchResultCell"
    let engine_key = "0b732cc0ea3c11874190"
    var textData: [String] = []
    var detailTextData: [String] = []
    var result: JSON!
    var urlData: [String] = []
    var searchContent: String = "" //搜索内容
    var searchPage: Int = 0 //当前搜索页数
    var MaxPage: Int!
    var isLoad: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //self.searchBar.showsScopeBar = true
        //self.searchBar.delegate = self
        //设置refrashControl
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "下拉刷新")
        self.refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        //self.tableView.addSubview(refreshControl)
        self.searchDisplayController!.searchResultsTableView.addSubview(refreshControl)
        //self.searchResultCell.addSubview(refreshControl)
    }
    
    //下拉刷新
    func refresh(sender:UIRefreshControl){
        // Code to refresh table view
        println("refrash")
        search(self.searchContent, page: 0)
        self.searchPage = 0
        self.refreshControl.endRefreshing()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //searchBar确认输入事件--搜索
    @IBAction func searchBarSearchButtonClicked(searchBar: UISearchBar!){
        search(searchBar.text, page: 0)
        self.searchPage = 0
    }
    
    @IBAction func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        println("start input")
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        println("end input")
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
    }
    
    //监听UIsearchBar输入改变--自动补全
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        autoComplete(searchText)
        self.searchContent = searchText
        self.searchPage = 0
    }
    
    /*
    tableView
    */
    //设置tableView显示行数
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.searchDisplayController!.searchResultsTableView {
            println("1  \(countElements(textData))")
            return countElements(textData)
        }
        println("2  \(countElements(textData))")
        return countElements(textData)
    }
    
    //设置tableView关联数据
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //设置cell
        //let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "MyTestCell")
        let cell: UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier(CellIdentifier) as UITableViewCell
        cell.textLabel.text = textData[indexPath.row]
        cell.detailTextLabel!.text = detailTextData[indexPath.row]
        return cell
    }
    
    //设置tableView点击事件--跳转url
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) -> UITableView{
        UIApplication.sharedApplication().openURL(NSURL(string : self.urlData[indexPath.row])!)
        return tableView
    }
    
    //上拉加载更多
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        //var offset = scrollView.contentOffset.y
        var offset = self.searchDisplayController!.searchResultsTableView.contentOffset.y
        println("offset \(offset)")
        //var maxOffset = scrollView.frame.size.height - scrollView.contentSize.height
        var maxOffset = self.searchDisplayController!.searchResultsTableView.frame.size.height - self.searchDisplayController!.searchResultsTableView.contentSize.height
        println("maxOffset \(maxOffset)")
        if (maxOffset - offset) <= 200 {
            if(self.isLoad){
                println("加载中")
            }else{
                println("准备加载")
                self.searchPage++
                if(self.searchPage > self.MaxPage){
                    println("没有更多了")
                }else{
                    self.search(searchContent, page: self.searchPage)
                }
            }
        }
    }
    
    //搜索
    func search(search_content: String,page: Int){
        if self.searchPage != 0 {
            self.isLoad = true
        }
        self.searchContent = search_content
        var tinySouClient = TinySouClient(engine_key: engine_key)
        if search_content.isEmpty {
            self.refrashUI()
            return
        }
        //开始搜索
        tinySouClient.setPage(page)
        var request = tinySouClient.buildRequest(search_content)
        let session = NSURLSession.sharedSession()
        var task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            if response == nil {
                self.alertError("网络无连接")
                return
            }
            let httpResp: NSHTTPURLResponse = response as NSHTTPURLResponse
            //响应状态码不为200时
            if(httpResp.statusCode != 200){
                if( error == nil ){
                    self.alertError(httpResp.statusCode)
                }else{
                    self.alertError(httpResp.statusCode, error: error)
                }
                return
            }
            var json = tinySouClient.handleResult(data) //处理json数据
            dispatch_async(
                //回调或者说是通知主线程刷新
                dispatch_get_main_queue(), {
                    self.refrashUI(json);//刷新UI
                    self.isLoad = false
            })
        })
        task.resume()
    }
    
    //自动补全
    func autoComplete(search_content: String){
        var tinySouClient = TinySouClient(engine_key: engine_key)
        if search_content.isEmpty {
            self.refrashUI()
            return
        }
        //开始自动补全
        var request = tinySouClient.buildAcRequest(search_content)
        let session = NSURLSession.sharedSession()
        var task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            if response == nil {
                self.alertError("网络无连接")
                return
            }
            let httpResp: NSHTTPURLResponse = response as NSHTTPURLResponse
            //响应状态码不为200时
            if(httpResp.statusCode != 200){
                if( error == nil ){
                    self.alertError(httpResp.statusCode)
                }else{
                    self.alertError(httpResp.statusCode, error: error)
                }
                return
            }
            var json = tinySouClient.handleResult(data) //处理json数据
            println("获取了json数据，准备刷新UI。。。")
            dispatch_async(
                //回调或者说是通知主线程刷新
                dispatch_get_main_queue(), {
                    self.refrashUI(json)//刷新UI
            })
        })
        task.resume()
    }
    
    //刷新tableView--空白
    func refrashUI(){
        self.textData.removeAll(keepCapacity: true)
        self.detailTextData.removeAll(keepCapacity: true)
        //self.searchDisplayControl.searchResultsTableView.reloadData()
        //self.searchResultCell.reloadData()
        self.tableView.reloadData()
    }
    
    //刷新tableView--普通
    func refrashUI(json: JSON) {
        if(self.searchPage == 0){
            self.textData.removeAll(keepCapacity: true)
            self.detailTextData.removeAll(keepCapacity: true)
            var total = Int(json["info"]["total"].number!)
            var per_page = Int(json["info"]["per_page"].number!)
            if total%per_page == 0 {
                self.MaxPage = total/per_page-1
            }else{
                self.MaxPage = total/per_page
            }
        }
        for var i=0; i < json["records"].count; i++ {
            var title = String(searchPage*10+i+1) + " " + json["records"][i]["document"]["title"].string!
            self.textData.insert(title, atIndex: i+searchPage*10)
            self.detailTextData.insert(json["records"][i]["document"]["sections"][0].string!, atIndex: i+searchPage*10)
            self.urlData.insert(json["records"][i]["document"]["url"].string!, atIndex: i+searchPage*10)
        }
        //self.tableView.reloadData()
        //self.searchResultCell.reloadData()
        self.searchDisplayController!.searchResultsTableView.reloadData()
    }
    
    //弹窗报错--不含报错信息
    func alertError(statusCode: Int) {
        var alert = UIAlertView()
        alert.title = String("网络异常: \(statusCode)")
        alert.addButtonWithTitle("OK!")
        dispatch_async(
            //回调或者说是通知主线程刷新
            dispatch_get_main_queue(), {
                alert.show()//弹窗报错
        })
    }
    
    //弹窗报错--含报错信息
    func alertError(statusCode: Int, error: NSError) {
        var alert = UIAlertView()
        alert.message = error.localizedDescription
        alert.title = String("网络异常: \(statusCode)")
        alert.addButtonWithTitle("OK!")
        dispatch_async(
            //回调或者说是通知主线程刷新
            dispatch_get_main_queue(), {
                alert.show()//弹窗报错
        })
    }
    
    //弹窗报错--string
    func alertError(error: String) {
        var alert = UIAlertView()
        alert.title = String("网络异常: \(error)")
        alert.addButtonWithTitle("OK!")
        dispatch_async(
            //回调或者说是通知主线程刷新
            dispatch_get_main_queue(), {
                alert.show()//弹窗报错
        })
        
    }

}

