//
//  DvdsViewController.swift
//  Rotten Tomatoes
//
//  Created by Marcus J. Ellison on 5/10/15.
//  Copyright (c) 2015 Marcus J. Ellison. All rights reserved.
//

import UIKit

class DvdsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var loaderView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var networkErrorView: UIView!
    @IBOutlet weak var dvdBarItem: UITabBarItem!
    @IBOutlet weak var bottomTabBar: UITabBar!
    @IBOutlet weak var moviesBarItem: UITabBarItem!
    
    let posterDefaultImage = UIImage(named: "posterDefault")
    
    @IBOutlet weak var loadingIndicatorView: UIActivityIndicatorView!
    var movies: [NSDictionary]?
    
    var refreshControl: UIRefreshControl!
    
    var scrollView: UIScrollView?
    
    //search bar

    @IBOutlet weak var dvdSearchBar: UISearchBar!
    var searchActive : Bool = false
    var filtered:[NSDictionary] = []
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.networkErrorView.hidden = true
        //        self.loaderView.hidden = true
        loadingIndicatorView.startAnimating()
        self.loadingIndicatorView.hidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = NSURL(string: "https://gist.githubusercontent.com/timothy1ee/e41513a57049e21bc6cf/raw/b490e79be2d21818f28614ec933d5d8f467f0a66/gistfile1.json")!
        let request = NSURLRequest(URL: url)
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) { (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
            
            // testing to see if there is a network connection.
            if data != nil {
                self.networkErrorView.hidden = true
                self.loadingIndicatorView.hidden = true
                
                let json = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) as? NSDictionary
                if let json = json {
                    self.movies = json["movies"] as? [NSDictionary]
                    self.tableView.reloadData()
                }
                
                
                self.loadingIndicatorView.startAnimating()
            } else {
                println("no data returned")
                self.networkErrorView.hidden = false
                self.loadingIndicatorView.hidden = false
            }
        }
        
        tableView.dataSource = self
        tableView.delegate = self
        dvdSearchBar.delegate = self
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "onRefresh", forControlEvents: UIControlEvents.ValueChanged)
        tableView.insertSubview(refreshControl, atIndex: 0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let movies = movies {
            if(searchActive) {
                return filtered.count
            } else {
                return movies.count
            }
            
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("MovieCell", forIndexPath: indexPath) as! MovieCell
        
        var movie: NSDictionary!
        
        if searchActive {
            movie = filtered[indexPath.row]
        } else {
            movie = movies![indexPath.row];
        }
        
        cell.titleLabel.text = movie["title"] as? String
        cell.synopsisLabel.text = movie["synopsis"] as? String
        
        var urlString = movie.valueForKeyPath("posters.thumbnail") as! String
        var range = urlString.rangeOfString(".*cloudfront.net/", options: .RegularExpressionSearch)
        if let range = range {
            urlString = urlString.stringByReplacingCharactersInRange(range, withString: "https://content6.flixster.com/")
        }
        let url = NSURL(string: urlString)
        
        cell.posterView.layer.opacity = 0
        cell.posterView.setImageWithURL(url, placeholderImage: posterDefaultImage)
        MovieCell.animateWithDuration(1, animations: {
            cell.posterView.alpha = 1
        })
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let cell = sender as! UITableViewCell
        
        let indexPath = tableView.indexPathForCell(cell)!
        
        let movie = movies![indexPath.row]
        
        let dvdDetailsViewController = segue.destinationViewController as! DvdDetailsViewController
        
        dvdDetailsViewController.movie = movie
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
    func onRefresh() {
        delay(2, closure: {
            self.refreshControl.endRefreshing()
        })
    }
    
    // search bar functions
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchActive = true;
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBar(dvdSearchBar: UISearchBar, textDidChange searchText: String) {
        
        filtered = movies!.filter({ (text) -> Bool in
            let tmp: AnyObject? = text["title"]
            let range = tmp!.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch)
            return range.location != NSNotFound
        })
        
        
        
        if(filtered.count == 0){
            searchActive = false;
        } else {
            searchActive = true;
        }
        
        
        self.tableView.reloadData()
    }
    
}
