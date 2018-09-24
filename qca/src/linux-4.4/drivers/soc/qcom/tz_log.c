/*
 * Copyright (c) 2015-2017, The Linux Foundation. All rights reserved.
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <linux/init.h>
#include <linux/module.h>
#include <linux/debugfs.h> /* this is for DebugFS libraries */
#include <linux/fs.h>
#include <linux/dma-mapping.h>
#include <linux/qcom_scm.h>
#include <linux/slab.h>

/* Maximum size for buffers to support AARCH64 TZ */
#define BUF_LEN 0x2000

#define TZ_INFO_GET_DIAG_ID 0x2

struct dentry *dirret, *fileret;

static char ker_buf[BUF_LEN] __aligned(8192), tmp_buf[BUF_LEN];

/* Read file operation */
static ssize_t tz_log_read(struct file *fp, char __user *user_buffer,
				size_t count, loff_t *position)
{
	int ret;
	uint16_t offset;
	uint16_t ring;
	uint32_t buf_len;
	uint32_t *ring_off;
	struct tzbsp_diag_log_t *log;
	uint16_t wrap;

	/* SCM call to TZ to get the tz log */
	ret = qcom_scm_tz_log(SCM_SVC_INFO, TZ_INFO_GET_DIAG_ID, ker_buf,
				&buf_len, &ring_off, &log);
	if (ret != 0) {
		pr_err("Error in getting tz log\n");
		return -EINVAL;
	}

	offset = log->log_pos.offset;
	ring = *ring_off;
	wrap = log->log_pos.wrap;

	if (wrap != 0) {
		memcpy(tmp_buf, (ker_buf + offset + ring),
					(buf_len - offset - ring));
		memcpy(tmp_buf + (buf_len - offset - ring), (ker_buf + ring),
					offset);
	} else {
		memcpy(tmp_buf, (ker_buf + ring), offset);
	}

	return simple_read_from_buffer(user_buffer, count,
					position, tmp_buf, buf_len);
}

static const struct file_operations fops_tz_log = {
	.read = tz_log_read,
};

static int __init init_tz_log(void)
{
	int filevalue;
	dirret = debugfs_create_dir("qcom_debug_logs", NULL);
	fileret = debugfs_create_file("tz_log", 0444, dirret,
					&filevalue, &fops_tz_log);

	return 0;
}

static void __exit exit_tz_log(void)
{
	/* removing the directory recursively which
	in turn cleans all the file */
	debugfs_remove_recursive(dirret);
}

module_init(init_tz_log);
module_exit(exit_tz_log);
