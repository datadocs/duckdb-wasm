import axios from 'axios';

import test_csv from '../../../data/test.csv';

export enum ExampleID {
    TEST_CSV,
}

export async function loadExample(id: ExampleID): Promise<File> {
    switch (id) {
        case ExampleID.TEST_CSV: {
            const res = await axios.get(test_csv);
            return new File(res.data(), 'test.csv');
        }
    }
}
