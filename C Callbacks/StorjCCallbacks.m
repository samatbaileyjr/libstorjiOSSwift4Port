//
//  StorjCallbacks.m
//  SwiftyStorj
//
//  Created by Andrea Tullis on 07/07/2017.
//  Copyright © 2017 angu2111. All rights reserved.
//

#import "StorjCallbacks.h"
#import <storj.h>
#import <Foundation/Foundation.h>

void get_info_callback(uv_work_t *work_req, int status)
{
    assert(status == 0);
    
    json_request_t *req = work_req->data;
    
    SJInfoCallBack callback = (__bridge SJInfoCallBack)req->handle;
    
    if (req->error_code || req->response == NULL) {
        free(req);
        free(work_req);
        if (req->error_code) {
            const char *errorMessage = curl_easy_strerror(req->error_code);
            printf("%s",errorMessage);
        }
        //TODO: Call the callback with an error
        exit(1);
    }
    
    struct json_object *info;
    json_object_object_get_ex(req->response, "info", &info);
    
    struct json_object *title;
    json_object_object_get_ex(info, "title", &title);
    struct json_object *description;
    json_object_object_get_ex(info, "description", &description);
    struct json_object *version;
    json_object_object_get_ex(info, "version", &version);
    struct json_object *host;
    json_object_object_get_ex(req->response, "host", &host);
    
    NSString *stringTitle = [[NSString alloc] initWithUTF8String:json_object_get_string(title)];
    NSString *stringDescription = [[NSString alloc] initWithUTF8String:json_object_get_string(description)];
    NSString *stringVersion = [[NSString alloc] initWithUTF8String:json_object_get_string(version)];
    NSString *stringHost = [[NSString alloc] initWithUTF8String:json_object_get_string(host)];
    
    callback(@{@"title":stringTitle,
               @"description":stringDescription,
               @"version": stringVersion,
               @"host":stringHost},nil);
    
    json_object_put(req->response);
    free(req);
    free(work_req);
}


void json_logger(const char *message, int level, void *handle)
{
    printf("\n{\"message\": \"%s\", \"level\": %i, \"timestamp\": %" PRIu64 "}",
           message, level, storj_util_timestamp());
}

void register_callback(uv_work_t *work_req, int status)
{
    assert(status == 0);
    json_request_t *req = work_req->data;
    
    if (req->status_code != 201) {
        printf("Request failed with status code: %i\n",
               req->status_code);
        struct json_object *error;
        json_object_object_get_ex(req->response, "error", &error);
        printf("Error: %s\n", json_object_get_string(error));

    } else {
        struct json_object *email;
        json_object_object_get_ex(req->response, "email", &email);
        printf("\n");
        printf("Successfully registered %s, please check your email "\
               "to confirm.\n", json_object_get_string(email));
        
}
    
    json_object_put(req->response);
    json_object_put(req->body);
    free(req);
    free(work_req);
}


void get_buckets_callback(uv_work_t *work_req, int status)
{
    assert(status == 0);
    get_buckets_request_t *req = work_req->data;
    
    SJBucketListCallBack callBack = (__bridge SJBucketListCallBack)(req->handle);
    NSMutableArray *buckets = [NSMutableArray new];
    if (req->status_code == 401) {
        printf("Invalid user credentials.\n");
    } else if (req->status_code != 200 && req->status_code != 304) {
        printf("Request failed with status code: %i\n", req->status_code);
    } else if (req->total_buckets == 0) {
        printf("No buckets.\n");
    }
    
    for (int i = 0; i < req->total_buckets; i++) {
        storj_bucket_meta_t *bucket = &req->buckets[i];
        printf("ID: %s \tDecrypted: %s \tCreated: %s \tName: %s\n",
               bucket->id, bucket->decrypted ? "true" : "false",
               bucket->created, bucket->name);
        NSString *_id = [[NSString alloc] initWithUTF8String:bucket->id];
        BOOL decrpypted = bucket->decrypted ? YES : NO;
        NSString *created = [[NSString alloc] initWithUTF8String:bucket->created];
        NSString *name = [[NSString alloc] initWithUTF8String:bucket->name];

        [buckets addObject:@{@"id":_id,
                             @"decrypted":@(decrpypted),
                             @"created": created,
                             @"name":name}];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        callBack(buckets,nil);
    });
    json_object_put(req->response);
    storj_free_get_buckets_request(req);
    free(work_req);
}

void create_bucket_callback(uv_work_t *work_req, int status)
{
    assert(status == 0);
    create_bucket_request_t *req = work_req->data;
    SJBucketCreateCallBack completion = (__bridge SJBucketCreateCallBack)req->handle;
    if (req->status_code == 404) {
        printf("Cannot create bucket [%s]. Name already exists \n", req->bucket->name);
        goto clean_variables;
    } else if (req->status_code == 401) {
        printf("Invalid user credentials.\n");
        goto clean_variables;
    }
    
    if (req->status_code != 201) {
        printf("Request failed with status code: %i\n", req->status_code);
        goto clean_variables;
    }
    
    if (req->bucket != NULL) {
        printf("ID: %s \tDecrypted: %s \tName: %s\n",
               req->bucket->id,
               req->bucket->decrypted ? "true" : "false",
               req->bucket->name);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *bucketName = [[NSString alloc] initWithUTF8String:req->bucket->name];
            completion(@{@"name":bucketName},nil);
        });
    } else {
        printf("Failed to add bucket.\n");
    }
    
    
    
clean_variables:
    json_object_put(req->response);
    free((char *)req->encrypted_bucket_name);
    free(req->bucket);
    free(req);
    free(work_req);
}

void file_progress(double progress,
                   uint64_t downloaded_bytes,
                   uint64_t total_bytes,
                   void *handle)
{
    int bar_width = 70;
    
    if (progress == 0 && downloaded_bytes == 0) {
        printf("Preparing File...");
        fflush(stdout);
        return;
    }
    
    printf("\r[");
    int pos = bar_width * progress;
    for (int i = 0; i < bar_width; ++i) {
        if (i < pos) {
            printf("=");
        } else if (i == pos) {
            printf(">");
        } else {
            printf(" ");
        }
    }
    printf("] %.*f%%", 2, progress * 100);
    
    fflush(stdout);
}

void upload_file_complete(int status, char *file_id, void *handle)
{
    printf("\n");
    if (status != 0) {
        printf("Upload failure: %s\n", storj_strerror(status));
        return;
    }
    
    printf("Upload Success! File ID: %s\n", file_id);
    dispatch_async(dispatch_get_main_queue(), ^{
        SJFileDeleteCallBack completion = (__bridge SJFileDeleteCallBack)(handle);
        completion(nil);
        Block_release(CFBridgingRetain(completion));
    });
    free(file_id);
    
}

void close_signal(uv_handle_t *handle)
{
    ((void)0);
}

void upload_signal_handler(uv_signal_t *req, int signum)
{
    storj_upload_state_t *state = req->data;
    storj_bridge_store_file_cancel(state);
    if (uv_signal_stop(req)) {
        printf("Unable to stop signal\n");
    }
    uv_close((uv_handle_t *)req, close_signal);
}

void download_signal_handler(uv_signal_t *req, int signum)
{
    storj_download_state_t *state = req->data;
    storj_bridge_resolve_file_cancel(state);
    if (uv_signal_stop(req)) {
        printf("Unable to stop signal\n");
    }
    uv_close((uv_handle_t *)req, close_signal);
}

void download_file_complete(int status, FILE *fd, void *handle)
{
    printf("\n");
    if (status) {
        // TODO send to stderr
        switch(status) {
                case STORJ_FILE_DECRYPTION_ERROR:
                printf("Unable to properly decrypt file, please check " \
                       "that the correct encryption key was " \
                       "imported correctly.\n\n");
                break;
            default:
                printf("Download failure: %s\n", storj_strerror(status));
        }
    }
    //Here we send the File back
    fseek(fd, 0L, SEEK_END);
    long sz = ftell(fd);
    rewind(fd);
    void *data = malloc(sz);
    fread(data, 1, sz, fd);
    fclose(fd);
    NSData *d = [NSData dataWithBytes:data length:sz];
    assert([NSThread isMainThread]);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        SJFileDownloadCallBack callback = (__bridge SJFileDownloadCallBack)handle;
        callback(d,nil);
        Block_release(CFBridgingRetain((__bridge id _Nullable)(handle)));
    });
    
    printf("Download Success!\n");
    free(data);
}

void list_mirrors_callback(uv_work_t *work_req, int status)
{
    assert(status == 0);
    json_request_t *req = work_req->data;
    
    if (req->status_code != 200) {
        printf("Request failed with status code: %i\n",
               req->status_code);
    }
    
    if (req->response == NULL) {
        free(req);
        free(work_req);
        printf("Failed to list mirrors.\n");
        exit(1);
    }
    
    int num_mirrors = json_object_array_length(req->response);
    
    struct json_object *shard;
    struct json_object *established;
    struct json_object *available;
    struct json_object *item;
    struct json_object *hash;
    struct json_object *contact;
    struct json_object *address;
    struct json_object *port;
    struct json_object *node_id;
    
    for (int i = 0; i < num_mirrors; i++) {
        printf("Established\n");
        printf("-----------\n");
        printf("Shard: %i\n", i);
        shard = json_object_array_get_idx(req->response, i);
        json_object_object_get_ex(shard, "established",
                                  &established);
        int num_established =
        json_object_array_length(established);
        for (int j = 0; j < num_established; j++) {
            item = json_object_array_get_idx(established, j);
            if (j == 0) {
                json_object_object_get_ex(item, "shardHash",
                                          &hash);
                printf("Hash: %s\n", json_object_get_string(hash));
            }
            json_object_object_get_ex(item, "contact", &contact);
            json_object_object_get_ex(contact, "address",
                                      &address);
            json_object_object_get_ex(contact, "port", &port);
            json_object_object_get_ex(contact, "nodeID", &node_id);
            const char *address_str =
            json_object_get_string(address);
            const char *port_str = json_object_get_string(port);
            const char *node_id_str =
            json_object_get_string(node_id);
            printf("\tstorj://%s:%s/%s\n", address_str, port_str, node_id_str);
        }
        
        printf("\nAvailable\n");
        printf("---------\n");
        printf("Shard: %i\n", i);
        json_object_object_get_ex(shard, "available",
                                  &available);
        int num_available =
        json_object_array_length(available);
        for (int j = 0; j < num_available; j++) {
            item = json_object_array_get_idx(available, j);
            if (j == 0) {
                json_object_object_get_ex(item, "shardHash",
                                          &hash);
                printf("Hash: %s\n", json_object_get_string(hash));
            }
            json_object_object_get_ex(item, "contact", &contact);
            json_object_object_get_ex(contact, "address",
                                      &address);
            json_object_object_get_ex(contact, "port", &port);
            json_object_object_get_ex(contact, "nodeID", &node_id);
            const char *address_str =
            json_object_get_string(address);
            const char *port_str = json_object_get_string(port);
            const char *node_id_str =
            json_object_get_string(node_id);
            printf("\tstorj://%s:%s/%s\n", address_str, port_str, node_id_str);
        }
    }
    
    json_object_put(req->response);
    free(req->path);
    free(req);
    free(work_req);
}


void list_files_callback(uv_work_t *work_req, int status)
{
    /*int ret_status = 0; unused variable */
    assert(status == 0);
    list_files_request_t *req = work_req->data;
    
    if (req->status_code == 404) {
        printf("Bucket id [%s] does not exist\n", req->bucket_id);
    } else if (req->status_code == 400) {
        printf("Bucket id [%s] is invalid\n", req->bucket_id);
    } else if (req->status_code == 401) {
        printf("Invalid user credentials.\n");
    } else if (req->status_code != 200) {
        printf("Request failed with status code: %i\n", req->status_code);
    }
    
    if (req->total_files == 0) {
        printf("No files for bucket.\n");
    }
    NSMutableArray *files = [NSMutableArray new];
    for (int i = 0; i < req->total_files; i++) {
        
        storj_file_meta_t *file = &req->files[i];
        
        printf("ID: %s \tSize: %" PRIu64 " bytes \tDecrypted: %s \tType: %s \tCreated: %s \tName: %s\n",
               file->id,
               file->size,
               file->decrypted ? "true" : "false",
               file->mimetype,
               file->created,
               file->filename);
        
        NSString *_id = [[NSString alloc] initWithUTF8String:file->id];
        NSString *filename = [[NSString alloc] initWithUTF8String:file->filename];
        [files addObject:@{@"id":_id,
                           @"filename":filename}];
    }
    
    SJFileListCallBack callback = (__bridge SJFileListCallBack)(req->handle);
    callback(files,nil);
    
cleanup:
    json_object_put(req->response);
    storj_free_list_files_request(req);
    free(work_req);
}

void delete_bucket_callback(uv_work_t *work_req, int status)
{
    assert(status == 0);
    json_request_t *req = work_req->data;
    SJBucketDeleteCallBack completion = (__bridge SJBucketDeleteCallBack)req->handle;
    if (req->status_code == 200 || req->status_code == 204) {
        printf("Bucket was successfully removed.\n");
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil);
        });
    } else if (req->status_code == 401) {
        printf("Invalid user credentials.\n");
    } else {
        printf("Failed to destroy bucket. (%i)\n", req->status_code);
    }
    
    json_object_put(req->response);
    free(req->path);
    free(req);
    free(work_req);
}

void delete_file_callback(uv_work_t *work_req, int status)
{
    assert(status == 0);
    json_request_t *req = work_req->data;
    
    if (req->status_code == 200 || req->status_code == 204) {
        printf("File was successfully removed from bucket.\n");
    } else if (req->status_code == 401) {
        printf("Invalid user credentials.\n");
    } else {
        printf("Failed to remove file from bucket. (%i)\n", req->status_code);
    }
    
    json_object_put(req->response);
    free(req->path);
    free(req);
    free(work_req);
}



