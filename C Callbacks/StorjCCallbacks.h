//
//  StorjCCallbacks.h
//  SwiftyStorj
//
//  Created by Andrea Tullis on 07/07/2017.
//  Copyright © 2017 angu2111. All rights reserved.
//

#ifndef StorjCCallbacks_h
#define StorjCCallbacks_h
#import "storj.h"

void json_logger(const char *message, int level, void *handle);

void get_info_callback(uv_work_t *work_req, int status);

void register_callback(uv_work_t *work_req, int status);

void get_buckets_callback(uv_work_t *work_req, int status);
void create_bucket_callback(uv_work_t *work_req, int status);
void delete_bucket_callback(uv_work_t *work_req, int status);

void file_progress(double progress,
                   uint64_t downloaded_bytes,
                   uint64_t total_bytes,
                   void *handle);

void upload_file_complete(int status, char *file_id, void *handle);
void download_file_complete(int status, FILE *fd, void *handle);
void delete_file_callback(uv_work_t *work_req, int status);

void list_mirrors_callback(uv_work_t *work_req, int status);
void list_files_callback(uv_work_t *work_req, int status);
#endif /* StorjCCallbacks_h */
