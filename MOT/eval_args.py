from absl import app
from absl import flags
import os
import pandas as pd

import evalMOT

FLAGS = flags.FLAGS

flags.DEFINE_string('benchmark_name', 'MOT17', 'Challenge name.')
flags.DEFINE_string('gt_dir', 'data', 'Directory that contains train/ and test/')
flags.DEFINE_string('eval_mode', 'train', 'Which subset, train or test.')
flags.DEFINE_string('res_dir', None, 'Directory containing predictions of one tracker.')
flags.DEFINE_string('seqmaps_dir', 'seqmaps', 'Challenge to evaluate.')
flags.DEFINE_string('output_file', None, 'CSV file to write metrics to.')
flags.DEFINE_string('debug_dir', None, 'Dir to write debug.')


def main(_):
    if FLAGS.debug_dir:
        os.makedirs(FLAGS.debug_dir, exist_ok=True)

    evaluator = evalMOT.MOT_evaluator(debug_dir=FLAGS.debug_dir)
    overall_metrics, sequence_metrics = evaluator.run(
            benchmark_name=FLAGS.benchmark_name,
            gt_dir=FLAGS.gt_dir,
            res_dir=FLAGS.res_dir,
            eval_mode=FLAGS.eval_mode,
            seqmaps_dir=FLAGS.seqmaps_dir)

    metrics = list(sequence_metrics) + [overall_metrics]
    values_dict = {m.seqName: m.val_dict() for m in metrics}
    values = pd.DataFrame.from_dict(values_dict, orient='index')
    values.index.name = 'sequence'
    print(values)
    if FLAGS.output_file:
        _ensure_parent_dir_exists(FLAGS.output_file)
        values.to_csv(FLAGS.output_file)


def _ensure_parent_dir_exists(fname):
    parent_dir = os.path.dirname(fname)
    if parent_dir:
        os.makedirs(parent_dir, exist_ok=True)


if __name__ == '__main__':
    flags.mark_flag_as_required('res_dir')
    app.run(main)
